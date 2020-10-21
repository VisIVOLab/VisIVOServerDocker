# Base image neaniasspace/vtk
FROM neaniasspace/vtk

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive

# get and build VisIVO Server
WORKDIR /opt
RUN git clone https://github.com/inaf-oact-VisIVO/VisIVOServer; \
cd /opt/VisIVOServer; \
git pull; git checkout 2.2;\
mkdir /opt/VisIVOServer/build; \ 
cd /opt/VisIVOServer/build; \ 
cmake -DCMAKE_INSTALL_PREFIX=/opt/VisIVOServer-2.2/ -DLIGHT=ON -DVSMAC=OFF -DCFITSIO_INCLUDE_DIR=/usr/include/ -DCFITSIO_LIB_DIR=/usr/lib/x86_64-linux-gnu/ -DHDF5_INCLUDE_DIR=/usr/include/hdf5/serial/ -DHDF5_LIB_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial/ ../; \
make -j8 && make install && rm -rf /tmp/* /opt/vtk /opt/VisIVOServer

ENV PATH="/opt/VisIVOServer-2.2/bin/:${PATH}"
WORKDIR /root/
ADD testfile /opt/testfile