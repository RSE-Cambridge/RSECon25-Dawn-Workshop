#/bin/bash
# Script for copying workshop setup scripts and kernels.
WORKSHOP_RDS="${HOME}/rds/rds-rsecon/kh296"

# Copyt setup scripts.
mkdir -p ../install
cp ${WORKSHOP_RDS}/install/*setup.sh ../install

# Link to shared miniforge3 directory.
rm -rf ~/miniforge3
ln -s ${WORKSHOP_RDS}/miniforge3 ~/miniforge3

# Copy kernel files, and update to current home directory.
JUPYTER_KERNELS_HOME="${HOME}/.local/share/jupyter/kernels"
JUPYTER_KERNELS_RDS="${WORKSHOP_RDS}/jupyter/kernels"
cp -r ${JUPYTER_KERNELS_RDS}/* ${JUPYTER_KERNELS_HOME}
for VENV in $(ls ${JUPYTER_KERNELS_HOME}); do
    sed -i "s@/.*/rds/@${HOME}/rds/@g" ${JUPYTER_KERNELS_HOME}/${VENV}/kernel.json
done
