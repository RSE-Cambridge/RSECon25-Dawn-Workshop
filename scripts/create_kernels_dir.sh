#/bin/bash

# Script that links default user directory for Jupyter kernels
# to user sub-directory of rds-rsecon,
# deleting any pre-existing kernels.

JUPYTER_KERNELS_HOME="${HOME}/.local/share/jupyter/kernels"
JUPYTER_KERNELS_RDS="${HOME}/rds/rds-rsecon/$(whoami)/jupyter/kernels"

rm -rf ${JUPYTER_KERNELS_HOME}
rm -rf ${JUPYTER_KERNELS_RDS}

mkdir -p ${JUPYTER_KERNELS_RDS}
ln -s ${JUPYTER_KERNELS_RDS} ${JUPYTER_KERNELS_HOME}

