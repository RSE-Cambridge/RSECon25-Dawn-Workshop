#!/bin/bash -l
#SBATCH --job-name=ddp-torch   # create a short name for the job
#SBATCH --output=%x.log        # job output file
#SBATCH --partition=pvc9       # cluster partition to be used
#SBATCH --account=support-gpu  # slurm project account
#SBATCH --nodes=2              # number of nodes
#SBATCH --gres=gpu:4         # number of allocated gpus per node
#SBATCH --time=01:00:00        # total run time limit (HH:MM:SS)

########################
# 0. Set environment variables that would usually be set by Slurm
########################
if [[ -z "${SLURM_NNODES}" ]]; then
    SLURM_NNODES=1
fi

if [[ -z "${SLURM_GPUS_ON_NODE}" ]]; then
    SLURM_NTASKS_PER_NODE=1
else
    SLURM_NTASKS_PER_NODE=$((2*${SLURM_GPUS_ON_NODE}))
fi
SLURM_NTASKS=$((${SLURM_NNODES}*${SLURM_NTASKS_PER_NODE}))

# Unset Slurm variables for sbatch submission from Slurm environment.
unset SLURM_MEM_PER_CPU
unset SLURM_MEM_PER_NODE

########################
# 1. Load Environment
########################
source ../install/ai-setup.sh

echo "==== Step: Python / mpiexec version check ===="
echo "Which python: $(which python)"
echo "Python version: $(python --version)"
echo "PyTorch version: $(python -c 'import torch; print(torch.__version__)')"
echo "Which mpiexec: $(which mpiexec)"
mpiexec --version

########################
# 2. Print job environment information
########################
export WORLD_SIZE=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))
echo "Node list: $SLURM_JOB_NODELIST"
echo "WORLD_SIZE=${WORLD_SIZE}"
#echo "Print environment variables (some may be large):"
#env | sort

########################
# 3. Set Intel MPI/OFI related environment variables
########################

# https://www.intel.com/content/www/us/en/developer/articles/technical/flattening-gpu-tile-hierarchy.html
export ZE_FLAT_DEVICE_HIERARCHY="FLAT"
export ZE_AFFINITY_MASK="0,1,2,3,4,5,6,7"

# export I_MPI_OFFLOAD=1
# export I_MPI_OFFLOAD_SYMMETRIC=0

# See: https://www.osc.edu/supercomputing/batch-processing-at-osc/slurm_migration/slurm_migration_issues
unset I_MPI_PMI_LIBRARY
export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=0

# Avoid CCL warning:
# [CCL_WARN] CCL_CONFIGURATION_PATH_modshare=:1 is unknown to and unused by
# oneCCL code but is present in the environment, check if it is not mistyped.
unset CCL_CONFIGURATION_PATH_modshare

# Avoid CCL warnings:
# |CCL_WARN| the number of workers (1) matches the number of available cores
# per process, this may lead to contention between workers and application
# threads
# |CCL_WARN| workers are disabled, to forcibly enable them
# set CCL_WORKER_OFFLOAD=1
#
# Note: setting CCL_WORKER_OFFLOAD=1 slows down processing.
export CCL_WORKER_OFFLOAD=1

# Use sockets instead of drmfd.
#export CCL_ZE_IPC_EXCHANGE=sockets
export CCL_ZE_IPC_EXCHANGE=pidfd

########################
# 4. Generate hostfile
########################
if [[ -z "${SLURM_JOB_NODELIST}" ]]; then
    hostname > mpi_hostfile.txt
else
    scontrol show hostnames $SLURM_JOB_NODELIST > mpi_hostfile.txt
fi
echo "Generated hostfile:"
cat mpi_hostfile.txt

########################
# 5. Set MASTER_ADDR/PORT
########################

if [[ -z "${SLURM_JOB_ID}" ]]; then
    MASTER_PORT=31415
else
    MASTER_PORT=$(( (SLURM_JOB_ID % 10000) + 10000 ))
fi
MASTER_ADDR=$(head -n1 mpi_hostfile.txt)

########################
# 6. Launch
########################

echo "==== Step: mpiexec start ===="

read -r -d "" CMD << EOS
mpiexec -n $WORLD_SIZE -ppn $SLURM_NTASKS_PER_NODE -f mpi_hostfile.txt\
 python mnist_classify_ddp.py\
 --epochs 1\
 --dist-url $MASTER_ADDR\
 --dist-port $MASTER_PORT\
 --ntasks-per-node $SLURM_NTASKS_PER_NODE
EOS
echo
echo "${CMD}"
echo
${CMD}

echo "==== Step: mpiexec done ===="
