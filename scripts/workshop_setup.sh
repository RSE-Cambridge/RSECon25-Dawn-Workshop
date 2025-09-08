#/bin/bash
# Script for copying workshop setup scripts and kernels.

WORKSHOP_RDS="/home/kh296/rds/rds-rsecon/kh296"

mkdir -p ../install
cp ${WORKSHOP_RDS}/install/*setup.sh ../install

JUPYTER_KERNELS_HOME="${HOME}/.local/share/jupyter/kernels"
JUPYTER_KERNELS_RDS="${WORKSHOP_RDS}/jupyter/kernels"
cp -rp ${JUPYTER_KERNELS_RDS}/* ${JUPYTER_KERNELS_HOME}
