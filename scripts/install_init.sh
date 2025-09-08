#/bin/bash
# Script to set up directories for software installation for this workshop.

USER_RDS=${HOME}/rds/rds-rsecon/$(whoami)
rm -rf ${USER_RDS}
mkdir -p ${USER_RDS}
chmod g-w ${USER_RDS}

INSTALL_RDS=${USER_RDS}/install
mkdir -p ${INSTALL_RDS}
cp ai_install.sh  miniforge3_install.sh  mlvenv_dawn.sh ${INSTALL_RDS}

# Link default user directory for Jupyter kernels
# to user sub-directory of rds-rsecon,
# deleting any pre-existing kernels.
JUPYTER_KERNELS_HOME="${HOME}/.local/share/jupyter/kernels"
JUPYTER_KERNELS_RDS="${HOME}/rds/rds-rsecon/$(whoami)/jupyter/kernels"

rm -rf ${JUPYTER_KERNELS_HOME}
rm -rf ${JUPYTER_KERNELS_RDS}

mkdir -p ${JUPYTER_KERNELS_RDS}
ln -s ${JUPYTER_KERNELS_RDS} ${JUPYTER_KERNELS_HOME}

cd ${INSTALL_RDS}
