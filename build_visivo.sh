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


VISIVO_BRANCH="llvm-compatibility"
VISIVO_COMMIT="0559282"
VISIVO_URL="https://github.com/VisIVOLab/VisIVOServer.git"

git clone -b $VISIVO_BRANCH --single-branch $VISIVO_URL
cd VisIVOServer
git checkout $VISIVO_COMMIT

mkdir build && cd build
cmake -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ../src 2>&1 | tee $PWD0/cmake.log
make -j$(nproc) && \
make install

