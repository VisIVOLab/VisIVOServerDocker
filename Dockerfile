# Base image ubuntu 20.04 (focal)

FROM ubuntu:focal

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Always update when extending base images
RUN apt update

#--------------
# Install deps
#---------------
RUN apt-get install -y build-essential
RUN apt-get install -y git curl cmake libgl1-mesa-dev libxt-dev libcfitsio-dev  cmake-curses-gui libhdf5-dev libcurl4-openssl-dev
RUN apt-get install -y libx11-dev libxt-dev libxext-dev libosmesa6-dev libglu1-mesa-dev
RUN apt-get install -y libboost1.67-all-dev

WORKDIR /opt

#get and build VTK 5.10.1
RUN git clone https://gitlab.kitware.com/vtk/vtk.git; 
RUN cd vtk; git checkout v5.10.1
# Apply patch to compile with gcc 9
RUN rm /opt/vtk/CMake/vtkCompilerExtras.cmake
ADD patch/vtkCompilerExtras.cmake /opt/vtk/CMake

RUN mkdir /opt/vtk/build
WORKDIR /opt/vtk/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/vtk-5/ -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS="-std=c++03 -DGLX_GLXEXT_LEGACY" -DVTK_OPENGL_HAS_OSMESA=ON -DVTK_USE_X=OFF -DVTK_USE_OFFSCREEN=ON ../
RUN make -j8;make install

# get and build VisIVO Server
WORKDIR /opt
RUN git clone https://github.com/inaf-oact-VisIVO/VisIVOServer
WORKDIR /opt/VisIVOServer
RUN git pull; git checkout 2.2

RUN mkdir /opt/VisIVOServer/build
WORKDIR /opt/VisIVOServer/build

RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/VisIVOServer-2.2/ -DLIGHT=ON -DVSMAC=OFF -DCFITSIO_INCLUDE_DIR=/usr/include/ -DCFITSIO_LIB_DIR=/usr/lib/x86_64-linux-gnu/ -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial/ -DHDF5_LIB_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial/ ../
RUN make -j8;make install

ENV PATH="/opt/VisIVOServer-2.2/bin/:${PATH}"

