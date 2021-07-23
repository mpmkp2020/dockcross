#!/bin/bash

# AUTHOR: odidev
# DATE: 2021-07-20
# DESCRIPTION: This file intended to cross compile the python and create necessary
#              crossenv enrironment

# The current env is not compatible to build python so resetting it as
# in quay.io/pypa/manylinux2014_x86_64 containers
unset $(env | awk -F= '{print $1}')
export SSL_CERT_FILE=/opt/_internal/certs.pem
export TERM=xterm
export LC_ALL=en_US.UTF-8
export LD_LIBRARY_PATH=/opt/rh/devtoolset-9/root/usr/lib64:/opt/rh/devtoolset-9/root/usr/lib:/opt/rh/devtoolset-9/root/usr/lib64/dyninst:/opt/rh/devtoolset-9/root/usr/lib/dyninst:/usr/local/lib64
export PATH=/opt/rh/devtoolset-9/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PWD=/work
export LANG=en_US.UTF-8
export AUDITWHEEL_ARCH=x86_64
export DEVTOOLSET_ROOTPATH=/opt/rh/devtoolset-9/root
export HOME=/root
export SHLVL=1
export LANGUAGE=en_US.UTF-8
export AUDITWHEEL_PLAT=manylinux2014_aarch64
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export AUDITWHEEL_POLICY=manylinux2014

# Python to be cross compiled
declare -A buildpy
buildpy=( ["3.6.13"]="cp36-cp36m" ["3.7.10"]="cp37-cp37m" ["3.8.9"]="cp38-cp38"  ["3.9.4"]="cp39-cp39")
python_vers="3.6.13 3.7.10 3.8.9 3.9.4"

# Adding cross compiler path in PATH env variable
export PATH=/usr/xcc/aarch64-unknown-linux-gnueabi/bin:$PATH

OLD_PATH=$PATH
CROSS_PY_BASE=/opt/_internal
CROSS_PY_BASE_LN=/opt/python
BUILD_DIR=/tmp/builds
LN=ln

# Loop over each python version and cross compile it
for python_ver in $python_vers; do
    echo ${python_ver}
    echo ${buildpy[$python_ver]}

    mkdir -p ${BUILD_DIR} && cd ${BUILD_DIR}
    wget https://www.python.org/ftp/python/${python_ver}/Python-${python_ver}.tgz
    tar xzf Python-${python_ver}.tgz
    cd Python-${python_ver}

    # Setting up build python path required by crassenv
    BUILD_PYBIN=${CROSS_PY_BASE_LN}/${buildpy[$python_ver]}/bin
    BUILD_PIP=${BUILD_PYBIN}/pip3
    BUILD_PYTHON=${BUILD_PYBIN}/python3
    
    # Setting up target python required by crossenv
    TARGET_PYPATH=${CROSS_PY_BASE}/xc/xcpython-${python_ver}
    TARGET_PYTHON=${TARGET_PYPATH}/bin/python3

    # Setting up cross env path
    CROSS_ENV=${CROSS_PY_BASE}/${buildpy[$python_ver]}-xc
    CROSS_ENV_LN=${CROSS_PY_BASE_LN}/${buildpy[$python_ver]}-xc
    CROSS_ENV_PIP=${CROSS_ENV_LN}/cross/bin/pip

    # Adding build python path as it is required to 
    # configure the python for cross compilation
    PATH=${BUILD_PYBIN}:${OLD_PATH}
    export PATH

    ./configure --prefix=${TARGET_PYPATH} \
                --host=aarch64-unknown-linux-gnueabi \
                --build=x86_64-linux-gnu \
                --without-ensurepip \
                ac_cv_buggy_getaddrinfo=no \
                ac_cv_file__dev_ptmx=yes \
                ac_cv_file__dev_ptc=no \
                --enable-optimizations
    make -j32 install
    make install

    # Create the necessary env and its link
    ${BUILD_PIP} install --upgrade pip crossenv
    ${BUILD_PYTHON} -m crossenv ${TARGET_PYTHON} ${CROSS_ENV}
    ${LN} -s  ${CROSS_ENV} ${CROSS_ENV_LN}
    ${CROSS_ENV_PIP} install wheel
    rm -rf ${BUILD_DIR}
done
