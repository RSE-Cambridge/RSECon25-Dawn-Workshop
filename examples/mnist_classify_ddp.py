import argparse
import importlib
import math
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torchvision import datasets, transforms
from torch.optim.lr_scheduler import StepLR

try:
    import intel_extension_for_pytorch as ipex
    loaded_ipex = True
except ModuleNotFoundError:
    loaded_ipex = False

# PyTorch XCCL backend enabled with Intel Extension for PyTorch v2.8.10+xpu.
if (not hasattr(torch.distributed, "is_xccl_available")) or loaded_ipex:
    torch.distributed.is_xccl_available = lambda: False
    if not torch.distributed.is_xccl_available():
        try:
            import oneccl_bindings_for_pytorch
        except ModuleNotFoundError:
            pass

import os
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP
from socket import gethostname

class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(9216, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.relu(x)
        x = F.max_pool2d(x, 2, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)
        return output

def train(args, device, model, train_loader, optimizer, epoch):
    model.train()
    n_batch = len(train_loader)
    size_task_dataset = sum(len(data) for (data, target) in train_loader)
    field_size = 1 + int(math.log10(size_task_dataset))
    size_done = 0
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        batch_idx2 = 1 + batch_idx
        size_done += len(data)
        if batch_idx2 % args.log_interval == 0 or batch_idx2 == n_batch:
            print('{}+{} Train Epoch: {} [{:{}d}/{:.0f} ({:2.0f}%)]'
                    '\tLoss: {:.6f}'.format(
                gethostname(), device, epoch,
                size_done, field_size, size_task_dataset,
                100. * size_done / size_task_dataset, loss.item()), flush=True)
            if args.dry_run:
                break

def test(model, device, test_loader):
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.nll_loss(output, target, reduction='sum').item()  # sum up batch loss
            pred = output.argmax(dim=1, keepdim=True)  # get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)

    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format(
        test_loss, correct, len(test_loader.dataset),
        100. * correct / len(test_loader.dataset)))

def setup(backend, rank, world_size, dist_url, dist_port):
    init_method = f"tcp://{dist_url}:{dist_port}"
    # initialize the process group
    dist.init_process_group(backend=backend, init_method=init_method,
            rank=rank, world_size=world_size)
    print(f"Added to process group: host: {gethostname()}, "
            f"rank: {rank}, world_size: {world_size}", flush=True)

def main():
    # Training settings
    parser = argparse.ArgumentParser(description='PyTorch MNIST Example')
    parser.add_argument('--ntasks-per-node', default=-1, type=int,
                        help='number of tasks per node for distributed training'
                        '; -1 for number of tasks equal to number of GPUs')
    parser.add_argument('--dist-url', default='127.0.0.1', type=str,
                        help='url used to set up distributed training')
    parser.add_argument('--dist-port', default='29500', type=str,
                        help='url port used to set up distributed training')
    parser.add_argument('--cpus-per-task', default=1, type=int,
                        help='number of CPUs per task')
    parser.add_argument('--batch-size', type=int, default=64, metavar='N',
                        help='input batch size for training (default: 64)')
    parser.add_argument('--test-batch-size', type=int, default=1000,
                        metavar='N',
                        help='input batch size for testing (default: 1000)')
    parser.add_argument('--epochs', type=int, default=20, metavar='N',
                        help='number of epochs to train (default: 14)')
    parser.add_argument('--lr', type=float, default=1.0, metavar='LR',
                        help='learning rate (default: 1.0)')
    parser.add_argument('--gamma', type=float, default=0.7, metavar='M',
                        help='Learning rate step gamma (default: 0.7)')
    parser.add_argument('--no-cuda', action='store_true', default=False,
                        help='disables CUDA training')
    parser.add_argument('--no-xpu', action='store_true', default=False,
                        help='disables Intel GPU training')
    parser.add_argument('--dry-run', action='store_true', default=False,
                        help='quickly check a single pass')
    parser.add_argument('--seed', type=int, default=1, metavar='S',
                        help='random seed (default: 1)')
    parser.add_argument('--log-interval', type=int, default=30, metavar='N',
                        help='how many batches to wait before logging training status')
    parser.add_argument('--save-model', action='store_true', default=False,
                        help='For Saving the current Model')
    args = parser.parse_args()

    backends = {"cpu": "gloo", "cuda": "nccl"}
    backends["xpu"] = "xccl" if torch.distributed.is_xccl_available() else "ccl"
    for device_type in ["cuda", "xpu"]:
        if getattr(args, f"no_{device_type}", False):
            continue
        try:
            device_module = importlib.import_module(f"torch.{device_type}")
        except ModuleNotFoundError:
            print("Module not found")
            device_module = None
        if getattr(device_module, "is_available", lambda: False)():
            break

    if -1 == args.ntasks_per_node:
        args.ntasks_per_node = device_module.device_count()

    torch.manual_seed(args.seed)
    
    train_kwargs = {'batch_size': args.batch_size}
    test_kwargs = {'batch_size': args.test_batch_size}
    if "cuda" == device_type:
        cuda_kwargs = {'num_workers': args.cpus_per_task,
                       'pin_memory': True,
                       'shuffle': True}
        train_kwargs.update(cuda_kwargs)
        test_kwargs.update(cuda_kwargs)

    transform=transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
        ])
    dataset1 = datasets.MNIST('data',
                              train=True,
                              download=False if os.path.isdir('data') else True,
                              transform=transform)
    dataset2 = datasets.MNIST('data',
                              train=False,
                              download=False,
                              transform=transform)

    world_size = int(os.environ.get("PMI_SIZE", 1))
    rank = int(os.environ.get("PMI_RANK", 0))

    setup(backends[device_type],
          rank, world_size, args.dist_url, args.dist_port)

    local_rank = rank - args.ntasks_per_node * (rank // args.ntasks_per_node)
    current_device = f"{device_type}:{local_rank}"
    device_module.set_device(current_device)
    print(f"host+device: {gethostname()}+{current_device}, "
            f"rank: {rank}, local_rank: {local_rank}, ", flush=True)

    train_sampler = torch.utils.data.distributed.DistributedSampler(
            dataset1,
            num_replicas=world_size,
            rank=rank)
    train_loader = torch.utils.data.DataLoader(dataset1,
                                               batch_size=args.batch_size,
                                               sampler=train_sampler,
                                               num_workers=args.cpus_per_task,
                                               pin_memory=True)

    test_loader = torch.utils.data.DataLoader(dataset2,
                                              **test_kwargs)
    model = Net().to(current_device)
    ddp_model = DDP(model, device_ids=[current_device])
    optimizer = optim.Adadelta(ddp_model.parameters(), lr=args.lr)

    scheduler = StepLR(optimizer, step_size=1, gamma=args.gamma)
    for epoch in range(1, args.epochs + 1):
        train(args, current_device, ddp_model, train_loader, optimizer, epoch)
        if rank == 0: test(ddp_model, current_device, test_loader)
        scheduler.step()

    if args.save_model and rank == 0:
        torch.save(model.state_dict(), "mnist_cnn.pt")

    dist.destroy_process_group()


if __name__ == '__main__':
    main()
