#/bin/bash
# Script for copying workshop setup scripts and kernels.
WORKDIR=$(pwd)
WORKSHOP_HOME="${HOME}/RSECon25-Dawn-Workshop"
WORKSHOP_RDS="${HOME}/rds/rds-rsecon/kh296"

# Copy setup scripts.
mkdir -p "${WORKSHOP_HOME}/install"
cp ${WORKSHOP_RDS}/install/*setup.sh ${WORKSHOP_HOME}/install

# Link to shared miniforge3 directory.
rm -rf ${HOME}/miniforge3
ln -s ${WORKSHOP_RDS}/miniforge3 ${HOME}/miniforge3

# Copy kernel files, and update to current home directory.
JUPYTER_KERNELS_HOME="${HOME}/.local/share/jupyter/kernels"
JUPYTER_KERNELS_RDS="${WORKSHOP_RDS}/jupyter/kernels"
cp -r ${JUPYTER_KERNELS_RDS}/* ${JUPYTER_KERNELS_HOME}
for VENV in $(ls ${JUPYTER_KERNELS_HOME}); do
    sed -i "s@/.*/rds/@${HOME}/rds/@g" ${JUPYTER_KERNELS_HOME}/${VENV}/kernel.json
done

# Clone repository with examples.
cd ${WORKSHOP_HOME}/..
if [ ! -d practical-ml-with-pytorch ]; then
  git clone https://github.com/kh296/practical-ml-with-pytorch
  cd practical-ml-with-pytorch
  git checkout xpu
  cd 
fi
cd ${WORKDIR}
