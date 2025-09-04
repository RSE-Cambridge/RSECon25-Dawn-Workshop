#!/bin/bash
#SBATCH --job-name=miniforge3_install  # create a short name for your job
#SBATCH --output=%x.log         # job output file
#SBATCH --partition=pvc9        # cluster partition to be used
#SBATCH --account=support-gpu   # slurm project account
#SBATCH --nodes=1               # number of nodes
#SBATCH --gres=gpu:1            # number of allocated gpus per node
#SBATCH --time=00:30:00         # total run time limit (HH:MM:SS)

# Start timer.
T0=${SECONDS}
CONDA_ENV="Miniforge3"
echo "Installation of ${CONDA_ENV} started on $(hostname): $(date)"
echo ""

# Exit at first failure.
set -e

# Delete any existing conda installation,
# and link default top-level location to subdirectory of hpc-work.
# Note: there is no backup of files under hpc-work - see:
# https://docs.hpc.cam.ac.uk/hpc/user-guide/io_management.html
CONDA_HOME="${HOME}/${CONDA_ENV,,}"
CONDA_RDS="${HOME}/rds/hpc-work/${CONDA_ENV,,}"
rm -rf "${CONDA_RDS}"
rm -rf "${CONDA_HOME}"
mkdir "${CONDA_RDS}"
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

# Report installation time.
echo ""
echo "Installation of miniforge3 completed: $(date)"
echo "Installation time: $((${SECONDS}-${T0})) seconds"
