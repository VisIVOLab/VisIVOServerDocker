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
RUN apt-get install -y git curl cmake libgl1-mesa-dev

WORKDIR /opt

#get VTK 6.0
RUN git clone https://gitlab.kitware.com/vtk/vtk.git
RUN mkdir /opt/vtk/build
WORKDIR /opt/vtk/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/vtk-6/ -DVTK_USE_OFFSCREEN=ON -DCMAKE_BUILD_TYPE=Release ../
RUN make;make install



#get VisIVO Server
RUN git clone https://www.ict.inaf.it/gitlab/VisIVO/VisIVOServer.git