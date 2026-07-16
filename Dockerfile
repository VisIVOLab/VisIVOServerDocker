# Stage 1: Builder
FROM almalinux:9 AS builder

LABEL maintainer=""
LABEL description="Builder Stage: Compiles LLVM, OSMesa, VTK, and VisIVO"

# Install dependencies
RUN dnf -y install epel-release && \
    dnf -y config-manager --set-enabled crb && \
    dnf makecache && \
    dnf -y install \
        python3 python3-devel \
        llvm clang git unzip wget \
        cfitsio-devel autoconf automake libtool \
        hdf5-devel libcurl-devel bzip2 make \
        boost-devel zlib-devel bison flex \
        binutils-devel patch perl-Data-Dumper \
        perl-FindBin libtirpc-devel glslang \
    && dnf clean all

COPY requirements.txt /opt/python38/
RUN mkdir -p /opt/python38 && \
    python3 -m venv /opt/python38 && \
    source /opt/python38/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r /opt/python38/requirements.txt

ENV CMAKE_VER="3.23.3"
RUN mkdir /tmp/cmake-install && cd /tmp/cmake-install && \
    wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.tar.gz && \
    tar -xf cmake-${CMAKE_VER}-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    cd / && rm -rf /tmp/cmake-install

RUN mkdir /tmp/ninja-install && cd /tmp/ninja-install && \
    wget -q https://github.com/ninja-build/ninja/releases/download/v1.11.0/ninja-linux.zip && \
    unzip ninja-linux.zip -d /usr/local/bin && \
    cd / && rm -rf /tmp/ninja-install

ENV LLVM_VER="14.0.6"
ARG CPU_ARCH="x86-64-v2"
ENV CFLAGS="-march=${CPU_ARCH}"
ENV CXXFLAGS="-march=${CPU_ARCH}"
RUN set -o pipefail && \
    mkdir -p /opt/llvm-build && cd /opt/llvm-build && \
    wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VER}/llvm-project-${LLVM_VER}.src.tar.xz && \
    tar -xf llvm-project-${LLVM_VER}.src.tar.xz && cd llvm-project-${LLVM_VER}.src && \
    mkdir build && cd build && \
    cmake -GNinja -DLLVM_ENABLE_PROJECTS="clang;lld;openmp" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_INSTALL_PREFIX="/usr/local" -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_RTTI=ON -DLLVM_INSTALL_UTILS=ON -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_ZLIB=OFF ../llvm && \
    ninja install && cd .. && rm -rf build && \
    mkdir build-stage2 && cd build-stage2 && \
    cmake -GNinja -DLLVM_ENABLE_PROJECTS="clang;lld;openmp" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_INSTALL_PREFIX="/usr/local" -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_RTTI=ON -DLLVM_INSTALL_UTILS=ON -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_ZLIB=OFF ../llvm && \
    ninja install && \
    cd / && rm -rf /opt/llvm-build

ENV MESA_VER="23.1.0"
RUN set -o pipefail && source /opt/python38/bin/activate && \
    mkdir -p /opt/mesa && cd /opt/mesa && \
    wget -q https://archive.mesa3d.org/mesa-${MESA_VER}.tar.xz && \
    tar -xf mesa-${MESA_VER}.tar.xz && cd mesa-${MESA_VER} && \
    mkdir build && \
    meson build -Dbuildtype=release -Dosmesa=true -Dgallium-drivers=swrast -Dglx=disabled -Ddri3=disabled -Degl=disabled -Dvulkan-drivers=[] -Dplatforms= -Dshared-llvm=false -Dshared-glapi=disabled -Dlibunwind=disabled -Dprefix=/usr/local && \
    ninja -C build install && cd / && rm -rf /opt/mesa

ARG TBB_VER="2021.5.0"
RUN mkdir /opt/TBB && cd /opt/TBB && \
    wget -q https://github.com/oneapi-src/oneTBB/releases/download/v${TBB_VER}/oneapi-tbb-${TBB_VER}-lin.tgz && \
    tar -xf oneapi-tbb-${TBB_VER}-lin.tgz && rm oneapi-tbb-${TBB_VER}-lin.tgz

RUN set -o pipefail && \
    curl -L -O https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.2.tar.gz && \
    tar -xzf openmpi-3.1.2.tar.gz && cd openmpi-3.1.2 && \
    ./configure CC=clang CXX=clang++ && make -j$(nproc) && make install && \
    cd / && rm -rf openmpi-3.1.2*

COPY build_vtk.sh /tmp/
RUN /tmp/build_vtk.sh && rm /tmp/build_vtk.sh

COPY build_visivo.sh /tmp/
RUN /tmp/build_visivo.sh && rm /tmp/build_visivo.sh

# Strip binaries to reduce size
RUN find /usr/local/bin /usr/local/lib /usr/local/lib64 -type f -exec strip --strip-unneeded {} + || true

# Stage 2
FROM almalinux:9

LABEL maintainer=""
LABEL description="VisIVO Server - Optimized Runtime Image"

RUN dnf -y install epel-release && \
    dnf -y config-manager --set-enabled crb && \
    dnf makecache && \
    dnf -y install --allowerasing \
        python3 \
        cfitsio \
        hdf5 \
        libcurl \
        bzip2 \
        zlib \
        libgomp \
        libstdc++ \
        openssh-clients \
    && dnf clean all

# Copy the built artifacts from the Builder stage
COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/TBB /opt/TBB
COPY --from=builder /opt/python38 /opt/python38

ENV PATH="/opt/python38/bin:/usr/local/bin:$PATH"
ENV OSMESA_ROOT="/usr/local"
ENV TBB_ROOT="/opt/TBB/oneapi-tbb-2021.5.0"

RUN echo /usr/local/lib64/ >> /etc/ld.so.conf.d/vtk.conf && \
    echo /opt/TBB/oneapi-tbb-2021.5.0/lib/intel64/gcc4.8/ >> /etc/ld.so.conf.d/libtbb.conf && \ 
    echo /usr/local/lib >> /etc/ld.so.conf.d/libomp.conf && \
    ldconfig

WORKDIR /app
CMD ["/bin/bash"]