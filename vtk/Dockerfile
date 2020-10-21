# Base neaniasspace/libmesa

FROM neaniasspace/libmesa

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive


#get and build VTK 5.10.1
WORKDIR /opt
RUN git clone https://gitlab.kitware.com/vtk/vtk.git; \
cd /opt/vtk; git checkout v5.10.1; \
rm /opt/vtk/CMake/vtkCompilerExtras.cmake
ADD patch/vtkCompilerExtras.cmake /opt/vtk/CMake

RUN mkdir /opt/vtk/build; \
cd /opt/vtk/build; \
cmake -DCMAKE_INSTALL_PREFIX=/opt/vtk-5/ -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS="-std=c++03 -DGLX_GLXEXT_LEGACY" -DVTK_OPENGL_HAS_OSMESA=ON -DVTK_USE_X=OFF -DVTK_USE_OFFSCREEN=ON -DOPENGL_INCLUDE_DIR="/usr/local/include" -DOPENGL_gl_LIBRARY="/usr/local/lib64/libGL.so" -DOPENGL_glu_LIBRARY="/usr/local/lib64/libGLU.so" -DOPENGL_xmesa_INCLUDE_DIR="/usr/local/include/GL" -DOSMESA_INCLUDE_DIR="/usr/local/include/GL" -DOSMESA_LIBRARY="/usr/local/lib64/libOSMesa.so" ../ ;  \
make -j8 && make install && rm -rf /tmp/* /opt/vtk 