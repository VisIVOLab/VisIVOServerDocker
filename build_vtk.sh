#!/bin/bash

echo "Compiling VTK"

set -o verbose
set -o errexit

PWD0=$(pwd)

# VTK compilation
VTK_BRANCH="master"
VTK_COMMIT="285daeedd58eb890cb90d6e907d822eea3d2d092"
VTK_URL="https://gitlab.kitware.com/vtk/vtk.git"

# Clone the VTK repository
git clone -b $VTK_BRANCH --single-branch $VTK_URL
cd vtk
git checkout $VTK_COMMIT

# Extract VTK version
VTK_MAJOR_VERSION=$(grep -oP '(?<=set\(VTK_MAJOR_VERSION )([0-9]+)' CMake/vtkVersion.cmake)
VTK_MINOR_VERSION=$(grep -oP '(?<=set\(VTK_MINOR_VERSION )([0-9]+)' CMake/vtkVersion.cmake)
VTK_BUILD_VERSION=$(grep -oP '(?<=set\(VTK_BUILD_VERSION )([0-9]+)' CMake/vtkVersion.cmake)
VTK_VER="${VTK_MAJOR_VERSION}.${VTK_MINOR_VERSION}.${VTK_BUILD_VERSION}"

# Create a build directory and configure the build
mkdir -p build && cd build  # Ensure proper path creation
export LDFLAGS="-fuse-ld=lld"

cmake -GNinja \
    -DVTK_BUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DVTK_OPENGL_HAS_OSMESA=True \
    -DVTK_USE_X=False \
    -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN=ON \
    -DVTK_SMP_IMPLEMENTATION_TYPE=TBB \
    -DVTK_SMP_ENABLE_SEQUENTIAL=ON \
    -DVTK_SMP_ENABLE_STDTHREAD=ON \
    -DVTK_SMP_ENABLE_TBB=ON \
    -DVTK_SMP_ENABLE_OPENMP=ON \
    -DVTK_INSTALL_SDK=ON \
    -DVTK_WRAP_PYTHON=ON \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DPYTHON_INCLUDE_DIR=/usr/include/python3.9 \
    -DPYTHON_LIBRARY=/usr/lib64/libpython3.9.so \
    ../ 2>&1 | tee $PWD0/cmake.log

# Build and install VTK
ninja 2>&1 | tee $PWD0/ninja.log
ninja install 2>&1 | tee $PWD0/ninja_install.log

