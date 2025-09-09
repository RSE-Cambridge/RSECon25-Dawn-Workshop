#!/bin/bash
#SBATCH --job-name=ai_install   # create a short name for your job
#SBATCH --output=%x.log         # job output file
#SBATCH --partition=pvc9        # cluster partition to be used
#SBATCH --nodes=1               # number of nodes
#SBATCH --gres=gpu:1            # number of allocated gpus per node
#SBATCH --time=02:00:00         # total run time limit (HH:MM:SS)

# Script for installing AI frameworks on Dawn supercomputer,
# including user installation of pytorch (version 2.8).
# Note: Installing multiple frameworks in a single environment risks
# creating conflicts.  Only limited functionality of the installed
# frameworks has been tested.
#
# This installation relies on the user having a miniforge installation
# at ~/miniforge3/bin/activate.  For instruction for installing miniforge, see:
# https://conda-forge.org/download/
#
# After installation, the environment for running lightning applications
# can be activated by sourcing the file ai-setup.sh, created
# in th directory where this script is run.
#
# This script may be run interactively on a Dawn compute node
# (not on a login node):
# bash ./ai_install.sh
# or it may be run on the Slurm batch system:
# sbatch --acount=<project account> ./ai_install.sh

T0=${SECONDS}
ENV_NAME="ai"
SOFTWARE="AI frameworks"
echo "Installation of ${SOFTWARE} started: $(date)"

# Create script for environment setup.
cat <<EOF >${ENV_NAME}-setup.sh
# Setup script for ${SOFTWARE} on Dawn supercomputer.
# Generated: $(date)

module purge
module load rhel9/default-dawn
module load intel-oneapi-mkl
module load intel-oneapi-compilers

# Initialise conda.
source ~/miniforge3/bin/activate

# Activate environment.
EOF

# Define installation environment.
source ${ENV_NAME}-setup.sh

# Create and activate conda environment.
#
# Package intelpython3_full provides Intel distribution for Python - see:
# https://www.intel.com/content/www/us/en/developer/tools/oneapi/distribution-python-download.html
#
# Installation of PyTorch based on instructions at:
# https://pytorch-extension.intel.com/installation?platform=gpu&version=v2.8.10%2Bxpu&os=linux%2Fwsl2&package=pip
#
# Instllation of Lightning based on instructions at:
# https://gitlab.developers.cam.ac.uk/kh296/lightning-xpu
#
# Installation of TensorFlow based on instructions at:
# https://github.com/intel/intel-extension-for-tensorflow
#
# Installation of JAX based on instructions at:
# https://github.com/intel/intel-extension-for-openxla/blob/main/docs/acc_jax.md
#
# Package level-zero needed for TensorFlow - see:
# https://github.com/oneapi-src/level-zero/issues/125
cat <<EOF >${ENV_NAME}.yml
name: ${ENV_NAME}
channels:
  - https://software.repos.intel.com/python/conda
  - conda-forge
  - nodefaults
dependencies:
  - intelpython3_full
#  - level-zero
  - python=3.11
  - pip
  - pip:
    - --index-url https://download.pytorch.org/whl/xpu
    - --extra-index-url https://pypi.org/simple
#    - tensorflow==2.15.0
#    - intel-extension-for-tensorflow[xpu]
    - lightning[extra]
    - litmodels
    - torch==2.8.0
    - torchaudio==2.8.0
    - torchvision==0.23.0
    - git+https://gitlab.developers.cam.ac.uk/kh296/lightning-xpu#egg=lightning_xpu
EOF

conda env remove -n ${ENV_NAME} -y
conda env create -f ${ENV_NAME}.yml
CMD="conda activate ${ENV_NAME}"
echo ${CMD} >> ${ENV_NAME}-setup.sh
${CMD}
python -m pip install --upgrade pip
# Installing JAX last seems to be best way of avoiding conflicts.
# Needs more checking.
python -m pip install intel-extension-for-openxla
python -m pip install -r https://raw.githubusercontent.com/intel/intel-extension-for-openxla/main/test/requirements.txt

# Allow group same non-write permissions as user.
chmod -R g=u-w ~/miniforge3/envs/ai

# Create Jupyter kernel.
pip install ipykernel
python -m ipykernel install --user --name=${ENV_NAME}

echo "${SOFTWARE} installation completed: $(date)"
echo "Installation time: $((${SECONDS}-${T0})) seconds"
