# Ubuntu Lucid-based compiler for Linux 2.6 kernel
# Lucid (10.04) has GCC 4.4 which is compatible with 2.6.39
FROM ubuntu:10.04
ARG ARCH

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

# Create directories
RUN mkdir -p /build /outputs /host/build
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
