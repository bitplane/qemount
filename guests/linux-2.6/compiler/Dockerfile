# Download sources using modern image with working TLS
FROM alpine:latest AS downloader
RUN apk add --no-cache wget
RUN wget -O /busybox.tar.bz2 https://busybox.net/downloads/busybox-1.36.1.tar.bz2
RUN wget -O /linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v2.6/linux-2.6.39.4.tar.xz

# Ubuntu Lucid-based compiler for Linux 2.6 kernel
# Lucid (10.04) has GCC 4.4 which is compatible with 2.6.39
FROM ubuntu:10.04

# Configure archive repositories (lucid is EOL)
RUN sed -i 's|archive.ubuntu.com|old-releases.ubuntu.com|g' /etc/apt/sources.list && \
    sed -i 's|security.ubuntu.com|old-releases.ubuntu.com|g' /etc/apt/sources.list

# Install GCC 4.4 and build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    bc \
    bison \
    flex \
    libncurses5-dev \
    libelf-dev \
    libssl-dev \
    perl \
    xz-utils \
    cpio \
    gzip \
    python

# GCC 4.4 is the default in lucid
ENV CC=gcc
ENV CXX=g++

# Create directories and copy pre-downloaded sources
RUN mkdir -p /build /outputs /host/build
COPY --from=downloader /busybox.tar.bz2 /build/
COPY --from=downloader /linux.tar.xz /build/
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
