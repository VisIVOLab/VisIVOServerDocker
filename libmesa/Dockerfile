# Base image neaniasspace/focalwithdeps
FROM neaniasspace/focalwithdeps

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /opt

#ADD and build LibMesa
ADD libs/MesaLib-7.5.2.tar.gz /tmp/
RUN cd /tmp/Mesa-7.5.2; make -j8 linux-x86-64; make install; \
echo "/usr/local/lib64" > /etc/ld.so.conf.d/mesa-x86_64.conf; \
ldconfig
