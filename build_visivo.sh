#!/bin/bash

echo "Compiling VisIVO Server"

source scl_source enable rh-git227
source scl_source enable rh-python38
source /opt/python38/bin/activate

set -o verbose
set -o errexit


find /usr/local -name "VTKConfig.cmake" -o -name "vtk-config.cmake"

VISIVO_BRANCH="main"
VISIVO_COMMIT="9d03d41"
VISIVO_URL="https://github.com/VisIVOLab/VisIVOServer"

git clone -b $VISIVO_BRANCH --single-branch $VISIVO_URL
cd VisIVOServer
git checkout $VISIVO_COMMIT

mkdir build && cd build
cmake -DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_CXX_FLAGS="-Wno-error=c++11-narrowing" -DCMAKE_C_COMPILER=mpicc -DHAS_CHANGA_IMPORTER=ON -DBUILD_API_LIGHT=OFF -DTBB_DIR=/opt/TBB/oneapi-tbb-2021.5.0/lib/cmake/tbb ../src 2>&1 | tee $PWD0/cmake.log
export CPATH=/usr/include/tirpc:$CPATH
make -j$(nproc) && \
make install
