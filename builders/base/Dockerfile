# Base builder image for qemount build system
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up locale
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Set environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install common build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    curl \
    git \
    python3 \
    python3-pip \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    rsync \
    cpio \
    cmake \
    ninja-build \
    pkg-config \
    autoconf \
    automake \
    libtool \
    xz-utils \
    zstd \
    unzip \
    meson \
    && rm -rf /var/lib/apt/lists/*

# Create build directories
RUN mkdir -p /build /cache /output

# Set working directory
WORKDIR /build

# Add a version identifier
RUN echo "qemount-builder-base:ubuntu-22.04" > /etc/qemount-builder-version