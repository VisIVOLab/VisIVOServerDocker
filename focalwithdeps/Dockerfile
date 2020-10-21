# Base image ubuntu 20.04 (focal)

FROM ubuntu:focal

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Always update when extending base images
#--------------
# Install deps
#---------------
RUN apt update; apt-get install --no-install-recommends -y build-essential \
git curl cmake  libxt-dev libcfitsio-dev  cmake-curses-gui libhdf5-dev libcurl4-openssl-dev \ 
libx11-dev libxt-dev libxext-dev \
libboost1.67-all-dev pkg-config libdrm-dev libxxf86vm-dev libxdamage-dev libxfixes-dev xutils-dev ca-certificates && apt-get clean all && rm -rf /var/lib/apt/lists/*
