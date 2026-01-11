ARG ARCH

FROM debian:bookworm-slim AS builder
ARG ARCH

# Install build dependencies for NetBSD build.sh
# Using Debian because musl libc (Alpine) has conflicts with old texinfo code
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    curl \
    ca-certificates \
    tar \
    xz-utils \
    gzip \
    bzip2 \
    zlib1g-dev \
    libncurses-dev \
    coreutils \
    findutils \
    diffutils \
    patch \
    gawk \
    sed \
    grep \
    texinfo \
    groff \
    flex \
    bison \
    perl \
    python3 \
    autoconf \
    automake \
    libtool \
    gettext \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download NetBSD 10.0 source
# src.tgz = base source, syssrc.tgz = kernel, sharesrc.tgz = share/mk
# gnusrc.tgz = external/gpl3 (binutils including mdsetimage)
RUN curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/src.tgz && \
    curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/syssrc.tgz && \
    curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/sharesrc.tgz && \
    curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/gnusrc.tgz

# Extract source
RUN mkdir -p /usr/src && \
    tar -xzf src.tgz -C / && \
    tar -xzf syssrc.tgz -C / && \
    tar -xzf sharesrc.tgz -C / && \
    tar -xzf gnusrc.tgz -C /

WORKDIR /usr/src

# Map architecture names and store in files for later stages
# ARCH comes in as x86_64, NetBSD uses amd64
# GNU triple prefix is used for cross tools (x86_64--netbsd-strip, etc)
RUN if [ "$ARCH" = "x86_64" ]; then \
        echo "amd64" > /tmp/nbarch; \
        echo "amd64" > /tmp/nbkernarch; \
        echo "x86_64" > /tmp/nbgnutriple; \
    elif [ "$ARCH" = "aarch64" ]; then \
        echo "evbarm" > /tmp/nbarch; \
        echo "evbarm" > /tmp/nbkernarch; \
        echo "aarch64" > /tmp/nbgnutriple; \
    else \
        echo "$ARCH" > /tmp/nbarch; \
        echo "$ARCH" > /tmp/nbkernarch; \
        echo "$ARCH" > /tmp/nbgnutriple; \
    fi

# Build cross-compilation toolchain
# This takes 30-60 minutes on first build
RUN NBARCH=$(cat /tmp/nbarch) && \
    ./build.sh -O /usr/obj -T /usr/tools -U -j$(nproc) -m $NBARCH tools

# Build distribution (includes rescue binaries needed for ramdisk)
RUN NBARCH=$(cat /tmp/nbarch) && \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j$(nproc) -m $NBARCH distribution

# Set up environment for cross-compilation
# Child images can use these for building binaries
ENV NETBSD_SRC=/usr/src
ENV NETBSD_OBJ=/usr/obj
ENV NETBSD_TOOLS=/usr/tools

# Create standard directories
RUN mkdir -p /build /outputs /host/build
WORKDIR /build

# Copy deployment script
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
