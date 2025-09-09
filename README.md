# RSECon25-Dawn-Workshop

## 1. Dawn

[Dawn](https://docs.hpc.cam.ac.uk/hpc/user-guide/pvc.html) is a supercomputer
hosted at the University of Cambridge, and is part
of the [AI Resource Research (AIRR)](https://www.gov.uk/government/publications/ai-research-resource/airr-advanced-supercomputers-for-the-uk).  It makes
available [Intel Data Centre GPU Max 1550](https://www.intel.com/content/www/us/en/products/sku/232873/intel-data-center-gpu-max-1550/specifications.html)
GPUs.  To install and run the workshop software on Dawn, you
will need to have been granted access.  For further information, see:
[Access to Dawn](https://www.csd3.cam.ac.uk/index.php/access-dawn).

## 2. Access to Dawn via the login-web interface

If you haven't done this already, and have an account, enable access to
Dawn via the [login-web interface](https://docs.hpc.cam.ac.uk/hpc/user-guide/login-web.html).

## 3. Connect to Jupyter server

Login at: [https://login-web.hpc.cam.ac.uk/](https://login-web.hpc.cam.ac.uk/)

At the top of the dashboard page presented after login, select:
```
Interactive Apps -> Jupyter Notebook
```

On the Jupyter Notebook form enter:
```
- Project account: training-dawn-gpu
- Partition: pvc9
- Reservation [leave blank]:
- Number of hours: 2
- Number of cores: 1
- Number of GPUs: 2
- Modules: intel-oneapi-mkl intel-oneapi-compilers jupyterlab
- Number of nodes: 1
```
The above request the resources needed for this workshop, for a period of
2 hours.  The number of hours may be decreased or increased as needed.

Click the __Launch__ button.

Your request for a Jupyter Notebook will progress through the states:
__Queued__, __Starting__, __Running__.  Once the __Running__ state is reached,
click the __Connect to Jupyter__ button.

Once connected to the Jupyter server, you will initially be shown the
__File Browser__, in the Jupyter Home tab.

## 4. Download examples and set up environment

On the Jupyter page, select:
```
File -> New -> Terminal
```
The Terminal window that opens will be in the home directory of your
account on Dawn.

Clone this repository to your home directory:
```
git clone https://github.com/RSE-Cambridge/RSECon25-Dawn-Workshop
```
Set up the environement:
```
source ~/RSECon25-Dawn-Workshop/scripts/workshop_setup.sh
```
This will clone another repository with examples (`practical-ml-with-pytorch`)
to your home directory, will create account-specific setup files in
`~/RSECon25-Dawn-Workshop/install` and will create kernel-definition files
in `~/.local/shared/jupyter/kernels`.

## 5. Submit batch jobs

Move to the workshop examples directory, and submit the two jobs that
perform multi-node processing:
```
cd ~/RSECon25-Dawn-Workshop/examples
sbatch --account=training-dawn-gpu run_mnist_classify_ddp.sh
sbatch --account=training-dawn-gpu run_lightning_toy_example.sh
```
## 6. Run Jupyter notebooks

On the Jupyter page, select:
```
File -> View -> Open JupyterLab
```
### 6.1 Check devices

In the left panel, navigate to `RSECon25-Dawn-Workshop/examples`.  Open,
and experiment with: `check_devices.ipynb`.  Before running the notebook,
set the kernel to `ai`:
```
Kernel -> Change Kernel... -> ai
```

### 6.2 Practical ml with PyTorch

In the left panel, navigate to `practical-ml-with-pytorch/worked-solutions`.
Open and experiment with the four notebooks.  Before running each notebook,
set the kernel to `practical-ml-with-pytorch`:
```
Kernel -> Change Kernel... -> practical-ml-with-pytorch
```
