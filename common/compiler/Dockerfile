FROM alpine:latest

# Install basic build tools and cross-compilers
RUN apk update && apk add --no-cache \
    build-base \
    gcc \
    g++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkgconfig \
    curl \
    wget \
    git \
    python3 \
    linux-headers \
    musl-dev \
    file \
    bison \
    flex \
    ncurses-dev \
    elfutils-dev \
    openssl-dev \
    xz \
    tar \
    bc \
    mtools \
    cpio \
    # For cross compilation - aarch64
    aarch64-none-elf-gcc \
    aarch64-none-elf-binutils \
    # For cross compilation - arm
    arm-none-eabi-gcc \
    arm-none-eabi-binutils \
    # For RISC-V if needed
    # riscv64-none-elf-gcc \
    # riscv64-none-elf-binutils \
    && rm -rf /var/cache/apk/*

# Create build directory
RUN mkdir -p /build /outputs

# Default to static linking for maximum portability
ENV CFLAGS="-static"
ENV CXXFLAGS="-static"
ENV LDFLAGS="-static"

WORKDIR /build
