# Base image ubuntu 20.04 (focal)

FROM ubuntu:focal

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Always update when extending base images
RUN apt update

#--------------
# Install deps
#---------------

# Git, Curlad and  Nano
RUN apt-get install git curl
