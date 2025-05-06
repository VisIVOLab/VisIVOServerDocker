#!/bin/bash

echo "Compiling VisIVO Server"

source scl_source enable rh-git227
source scl_source enable rh-python38
source /opt/python38/bin/activate

set -o verbose
set -o errexit


#wget http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-4.1.0.tar.gz
#tar xzf cfitsio-4.1.0.tar.gz
#cd cfitsio-4.1.0
#./configure --prefix=/usr/local
#make
#make install


VISIVO_BRANCH="main"
VISIVO_COMMIT="f199658"
VISIVO_URL="https://github.com/VisIVOLab/VisIVOServer"

wget http://rpmfind.net/linux/centos-stream/10-stream/BaseOS/x86_64/os/Packages/libtirpc-1.3.5-0.el10.x86_64.rpm
git clone -b $VISIVO_BRANCH --single-branch $VISIVO_URL
cd VisIVOServer
git checkout $VISIVO_COMMIT

mkdir build && cd build
cmake -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc -DBUILD_API_LIGHT=OFF ../src 2>&1 | tee $PWD0/cmake.log
export CPATH=/usr/include/tirpc:$CPATH
make -j$(nproc) && \
make install

