FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install git ssh make gcc libssl-dev \
    liblz4-tool expect expect-dev g++ patchelf chrpath gawk texinfo chrpath \
    diffstat binfmt-support qemu-user-static live-build bison flex fakeroot \
    cmake gcc-multilib g++-multilib unzip device-tree-compiler ncurses-dev \
    libgucharmap-2-90-dev bzip2 expat gpgv2 cpp-aarch64-linux-gnu libgmp-dev \
    libmpc-dev bc python-is-python3 python2 curl file rsync bsdmainutils scons

RUN ln -sf /usr/bin/python2 /usr/bin/python

