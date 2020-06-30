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



WORKDIR /opt

#get VTK 6.0
RUN git clone https://gitlab.kitware.com/vtk/vtk.git; 
RUN cd vtk; git checkout v5.10.1
# Apply patch to compile with gcc 9
RUN rm /opt/vtk/CMake/vtkCompilerExtras.cmake
#RUN rm /opt/vtk/CMake/GenerateExportHeader.cmake
ADD patch/vtkCompilerExtras.cmake /opt/vtk/CMake
#ADD patch/GenerateExportHeader.cmake /opt/vtk/CMake

RUN mkdir /opt/vtk/build
WORKDIR /opt/vtk/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/vtk-6/ -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF ../
#RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/vtk-6/ -DVTK_USE_OFFSCREEN=ON -DCMAKE_BUILD_TYPE=Release -DVTK_OPENGL_HAS_OSMESA=ON -DVTK_USE_X=OFF -DBUILD_SHARED_LIBS=OFF ../
RUN make -j8;make install

# get VisIVO Server

WORKDIR /opt
RUN ls
RUN git clone https://github.com/inaf-oact-VisIVO/VisIVOServer
WORKDIR /opt/VisIVOServer
RUN git pull; git checkout 2.2

RUN mkdir /opt/VisIVOServer/build
WORKDIR /opt/VisIVOServer/build

RUN cmake -DLIGHT=ON -DVSMAC=OFF -DCFITSIO_INCLUDE_DIR=/usr/include/ -DCFITSIO_LIB_DIR=/usr/lib/x86_64-linux-gnu/ -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial/ -DHDF5_LIB_DIR=/usr/lib/x86_64-linux-gnu/ ../
