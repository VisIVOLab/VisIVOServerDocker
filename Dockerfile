FROM almalinux:9
LABEL maintainer="Håkon Strandenes <h.strandenes@km-turbulenz.no>"
LABEL description="LLVM+OSMesa compiled from sources"

RUN dnf -y install epel-release && \
    dnf -y update && \
    dnf -y install python3 python3-devel \
                   llvm clang git unzip \
                   wget cfitsio-devel autoconf automake libtool hdf5-devel libcurl-devel bzip2 make boost-devel zlib-devel bison flex binutils-devel patch perl-Data-Dumper perl-FindBin && \
    dnf -y --enablerepo=crb install libtirpc-devel && \
    dnf clean all

# Python 3.8 package installation along with basic packages
COPY requirements.txt /opt/python38/
RUN mkdir -p /opt/python38 && \
    python3 -m venv /opt/python38 && \
    source /opt/python38/bin/activate && \
    pip install --upgrade pip && \
    pip install -r /opt/python38/requirements.txt


# Fetch and install updated CMake in /usr/local
ENV CMAKE_VER="3.23.3"
ARG CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.tar.gz"
RUN mkdir /tmp/cmake-install && \
    cd /tmp/cmake-install && \
    wget --no-verbose $CMAKE_URL && \
    tar -xf cmake-${CMAKE_VER}-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    cd / && \
    rm -rf /tmp/cmake-install

# Fetch and install updated Ninja-build in /usr/local
ARG NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v1.11.0/ninja-linux.zip"
RUN mkdir /tmp/ninja-install && \
    cd /tmp/ninja-install && \
    wget --no-verbose $NINJA_URL && \
    unzip ninja-linux.zip -d /usr/local/bin && \
    cd / && \
    rm -rf /tmp/ninja-install

# Download LLVM sources
ENV LLVM_VER="14.0.6"
ARG LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VER}/llvm-project-${LLVM_VER}.src.tar.xz"
RUN set -o pipefail && \
    mkdir -p /opt/llvm-build && \
    cd /opt/llvm-build && \
    wget --no-verbose $LLVM_URL && \
    tar -xf llvm-project-${LLVM_VER}.src.tar.xz && \
    rm llvm-project-${LLVM_VER}.src.tar.xz

# Compile LLVM + Clang compilation using LLVM-7 from Centos SCL
RUN set -o pipefail && \
    cd /opt/llvm-build/llvm-project-${LLVM_VER}.src && \
    mkdir build && \
    cd build && \
    cmake -GNinja \
        -DLLVM_ENABLE_PROJECTS="clang;lld;openmp" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DLLVM_TARGETS_TO_BUILD=X86 \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_INSTALL_UTILS=ON \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_ENABLE_ZLIB=OFF \
        ../llvm 2>&1 | tee cmake.log && \
    ninja 2>&1 | tee ninja.log && \
    ninja install 2>&1 | tee ninja_install.log && \
    cd .. && \
    rm -rf build

# CPU architecture for optimizations
ARG CPU_ARCH="x86-64-v2"
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"

# LLVM stage 2 compilation - building LLVM and libLLVM with x86-64-v2
# architecture flag
RUN set -o pipefail && \
    cd /opt/llvm-build/llvm-project-${LLVM_VER}.src/ && \
    mkdir build-stage2 && \
    cd build-stage2 && \
    cmake -GNinja \
        -DLLVM_ENABLE_PROJECTS="clang;lld;openmp" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DLLVM_TARGETS_TO_BUILD=X86 \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_INSTALL_UTILS=ON \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_ENABLE_ZLIB=OFF \
        ../llvm 2>&1 | tee cmake.log && \
    ninja 2>&1 | tee ninja.log && \
    ninja install 2>&1 | tee ninja_install.log && \
    cd .. && \
    rm -rf build-stage2

# Download Mesa3D library
ENV MESA_VER="23.1.0"
ARG MESA_URL="https://archive.mesa3d.org/mesa-${MESA_VER}.tar.xz"
RUN mkdir -p /opt/mesa && \
    cd /opt/mesa && \
    wget --no-verbose $MESA_URL && \
    tar -xf mesa-${MESA_VER}.tar.xz && \
    rm mesa-${MESA_VER}.tar.xz

# Compile OSMesa
RUN set -o pipefail && \
    source /opt/python38/bin/activate && \
    cd /opt/mesa/mesa-${MESA_VER} && \
    mkdir build && \
    meson build \
        -Dbuildtype=release \
        -Dosmesa=true \
        -Dgallium-drivers=swrast \
        -Dglx=disabled \
        -Ddri3=disabled \
        -Degl=disabled \
        -Dvulkan-drivers=[] \
        -Dplatforms= \
        -Dshared-llvm=false \
        -Dshared-glapi=disabled \
        -Dlibunwind=disabled \
        -Dprefix=/usr/local 2>&1 | tee cmake.log && \
    ninja -C build install 2>&1 | tee ninja.log && \
    rm -rf build

ENV OSMESA_ROOT="/usr/local"

# Thread Building Blocks (TBB) download and unpack
ARG TBB_VER="2021.5.0"
ARG TBB_URL="https://github.com/oneapi-src/oneTBB/releases/download/v2021.5.0/oneapi-tbb-2021.5.0-lin.tgz"
RUN mkdir /opt/TBB && \
    cd /opt/TBB && \
    wget --no-verbose $TBB_URL && \
    tar -xf oneapi-tbb-${TBB_VER}-lin.tgz && \
    rm oneapi-tbb-${TBB_VER}-lin.tgz
ENV TBB_ROOT="/opt/TBB/oneapi-tbb-${TBB_VER}"

#VTK
ADD build_vtk.sh /tmp/
RUN /tmp/build_vtk.sh

RUN curl -O https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.2.tar.gz && \
    tar -xzf openmpi-3.1.2.tar.gz && \
    cd openmpi-3.1.2 && \
    ./configure CC=clang CXX=clang++ && \
    make -j$(nproc) && \
    make install

ADD build_visivo.sh /tmp/
RUN /tmp/build_visivo.sh

RUN echo /usr/local/lib64/ >> /etc/ld.so.conf.d/vtk.conf && \
echo /opt/TBB/oneapi-tbb-2021.5.0/lib/intel64/gcc4.8/ >> /etc/ld.so.conf.d/libtbb.conf && \ 
echo /usr/local/lib >> /etc/ld.so.conf.d/libomp.conf && \
ldconfig
