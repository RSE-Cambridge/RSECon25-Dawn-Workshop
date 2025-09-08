#!/bin/bash
#SBATCH --job-name=miniforge3_install  # create a short name for your job
#SBATCH --output=%x.log         # job output file
#SBATCH --partition=pvc9        # cluster partition to be used
#SBATCH --nodes=1               # number of nodes
#SBATCH --gres=gpu:1            # number of allocated gpus per node
#SBATCH --time=00:30:00         # total run time limit (HH:MM:SS)

# Script for installing the Miniforge3 flavour of conda
# on the Dawn supercomputer.
# For information about miniforge, see:
# https://github.com/conda-forge/miniforge

# This script may be run interactively on a Dawn login or compute node:
# bash ./miniforge3_install.sh
# or it may be run on the Slurm batch system:
# sbatch --acount=<project account> ./miniforge3_install.sh

# Start timer.
T0=${SECONDS}
CONDA_ENV="Miniforge3"
echo "Installation of ${CONDA_ENV} started on $(hostname): $(date)"
echo ""

# Exit at first failure.
set -e

# Delete any existing conda installation,
# and link default top-level location to user subdirectory of rds-rsecon.
CONDA_HOME="${HOME}/${CONDA_ENV,,}"
CONDA_RDS="${HOME}/rds/rds-rsecon/$(whoami)/${CONDA_ENV,,}"
rm -rf "${CONDA_RDS}"
rm -rf "${CONDA_HOME}"
mkdir -p "${CONDA_RDS}"
ln -s "${CONDA_RDS}" "${CONDA_HOME}"

# Download and run the installation script.
INSTALL_SCRIPT="Miniforge3-$(uname)-$(uname -m).sh"
rm -rf "${INSTALL_SCRIPT}"
wget "https://github.com/conda-forge/miniforge/releases/latest/download/${INSTALL_SCRIPT}"
bash "${INSTALL_SCRIPT}" -b -u -p "${CONDA_HOME}"
rm "${INSTALL_SCRIPT}"

# Update to latest conda version.
source ${CONDA_HOME}/bin/activate
conda update -n base -c conda-forge conda -y

# Allow group same non-write permissions as user.
chmod -R g=u-w "${CONDA_RDS}"

# Report installation time.
echo ""
echo "Installation of miniforge3 completed: $(date)"
echo "Installation time: $((${SECONDS}-${T0})) seconds"
