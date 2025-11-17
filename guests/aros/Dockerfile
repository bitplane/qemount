FROM docker.io/debian:bookworm-slim

# Install AROS build dependencies (from Azure CI + GPT research)
RUN apt-get update && apt-get install -y \
    gcc g++ gcc-multilib make gawk bison flex byacc \
    git wget curl ca-certificates bzip2 xz-utils unzip \
    netpbm automake cmake autoconf genisoimage sshpass libtool \
    libpng-dev zlib1g-dev libjpeg-dev liblzo2-dev \
    libxcursor-dev libgl1-mesa-dev libasound2-dev \
    libsdl1.2-dev libx11-dev libxext-dev libxxf86vm-dev libc6-dev \
    python3 python3-mako python3-distutils-extra \
    ccache texinfo \
    libswitch-perl gperf \
    libgmp-dev libmpfr-dev libmpc-dev \
    liblzma-dev mtools xorriso nasm

# Create build directory
RUN mkdir -p /build

# Wrap tar to always use --no-same-owner (fixes container ownership issues)
RUN mv /bin/tar /bin/tar.real
COPY tar-wrapper.sh /bin/tar
RUN chmod +x /bin/tar

WORKDIR /build

# Clone AROS source from bitplane fork (qemount branch) + make backup
WORKDIR /build
RUN git clone https://github.com/bitplane/AROS.git && \
    cd AROS && \
    git checkout qemount && \
    git submodule update --init && \
    cp -r /build/AROS /build/AROS.bak

WORKDIR /build/AROS

# ============================================================================
# TWO-PHASE BUILD PROCESS (Azure CI pattern)
# ============================================================================
# Phase 1: Build crosstools
# Phase 2: Clean bin/, re-configure with --with-aros-toolchain=yes, build floppy
#
# Commands below are commented out for manual testing.
# Uncomment each section after verifying it works.
# ============================================================================

# --- PHASE 1: Build Crosstools ---
# Configure to build crosstools WITH tiny variant settings
# (toolchain must be built with same config as final build)
RUN ./configure --target=pc-i386 \
    --with-aros-toolchain-install=/build/toolchain \
    --with-portssources=/build/portssources \
    --enable-ccache \
    --enable-build-type=nightly \
    --enable-target-variant=tiny \
    --with-optimization="-Os -fno-defer-pop -mpreferred-stack-boundary=4"

# Build crosstools (installs to /build/toolchain)
RUN make -j$(nproc) crosstools

# --- PHASE 2: Build AROS Boot Floppy ---
# CRITICAL: refresh repo, get rid of build mess.
RUN rm -rf /build/AROS && \
    mv /build/AROS.bak /build/AROS

# Re-configure to USE the pre-built toolchain with floppy-specific settings
RUN ./configure --target=pc-i386 \
    --with-aros-toolchain-install=/build/toolchain \
    --with-aros-toolchain=yes \
    --enable-build-type=nightly \
    --enable-target-variant=tiny \
    --with-optimization="-Os -fno-defer-pop -mpreferred-stack-boundary=4" \
    --with-theme=AmigaOS3.x \
    --with-iconset=Mason \
    --with-bootloader=grub \
    --with-portssources=/build/portssources \
    --enable-ccache

# Build boot floppy and system floppy images
# First run make to build core system and fetch dependencies (like grub)
RUN make -j2
# Then build the floppy disk images
RUN make bootdisk systemdisk

# Copy output images to /outputs
RUN mkdir -p /outputs/guests/aros-i386 && \
    cp distfiles/aros-pc-i386.img /outputs/guests/aros-i386/ && \
    cp distfiles/system-pc-i386.img /outputs/guests/aros-i386/ && \
    echo "arch=i386" > /outputs/guests/aros-i386/meta.conf
