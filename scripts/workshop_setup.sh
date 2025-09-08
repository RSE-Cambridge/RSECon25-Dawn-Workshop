#/bin/bash
# Script for copying workshop setup scripts and kernels.

WORKSHOP_RDS="${HOME}/rds/rds-rsecon/kh296"

mkdir -p ../install
cp ${WORKSHOP_RDS}/install/*setup.sh ../install

rm -rf ~/miniforge3
ln -s ${WORKSHOP_RDS}/miniforge3 ~/miniforge3

JUPYTER_KERNELS_HOME="${HOME}/.local/share/jupyter/kernels"
JUPYTER_KERNELS_RDS="${WORKSHOP_RDS}/jupyter/kernels"
cp -r ${JUPYTER_KERNELS_RDS}/* ${JUPYTER_KERNELS_HOME}
