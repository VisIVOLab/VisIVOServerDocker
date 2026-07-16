#!/bin/bash
set -e
set -o pipefail
set -o verbose

echo "Compiling VTK"

PWD0=$(pwd)

VTK_BRANCH="master"
VTK_COMMIT="285daeedd58eb890cb90d6e907d822eea3d2d092"
VTK_URL="https://gitlab.kitware.com/vtk/vtk.git"

git clone -b "$VTK_BRANCH" --single-branch "$VTK_URL"
cd vtk
git checkout "$VTK_COMMIT"

mkdir -p build
cd build

export LDFLAGS="-fuse-ld=lld"

cmake -GNinja \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DVTK_BUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DVTK_OPENGL_HAS_OSMESA=ON \
    -DVTK_USE_X=OFF \
    -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN=ON \
    -DVTK_SMP_IMPLEMENTATION_TYPE=TBB \
    -DVTK_SMP_ENABLE_SEQUENTIAL=ON \
    -DVTK_SMP_ENABLE_STDTHREAD=ON \
    -DVTK_SMP_ENABLE_TBB=ON \
    -DVTK_SMP_ENABLE_OPENMP=ON \
    -DVTK_INSTALL_SDK=ON \
    -DVTK_WRAP_PYTHON=ON \
    -DTBB_DIR=/opt/TBB/oneapi-tbb-2021.5.0/lib/cmake/tbb \
    -DPython3_EXECUTABLE=/opt/python38/bin/python3 \
    -DPython3_INCLUDE_DIR=/usr/include/python3.9 \
    -DPython3_LIBRARY=/usr/lib64/libpython3.9.so \
    .. 2>&1 | tee "$PWD0/cmake.log"

ninja 2>&1 | tee "$PWD0/ninja.log"
ninja install 2>&1 | tee "$PWD0/ninja_install.log"

echo "Installed VTKConfig files:"
find /usr/local \( -name "VTKConfig.cmake" -o -name "vtk-config.cmake" \) -print