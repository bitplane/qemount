ARG OUTPUT_ARCH
ARG BUILD_PLATFORM
ARG JOBS=1

FROM debian:bookworm-slim AS builder
ARG OUTPUT_ARCH
ARG BUILD_PLATFORM
ARG JOBS=1

# Install build dependencies for NetBSD build.sh
# Using Debian because musl libc (Alpine) has conflicts with old texinfo code
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
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

# Extract source from mounted build_requires
RUN mkdir -p /usr/src && \
    tar -xzf /host/build/sources/netbsd-10.0-src.tgz -C / && \
    tar -xzf /host/build/sources/netbsd-10.0-syssrc.tgz -C / && \
    tar -xzf /host/build/sources/netbsd-10.0-sharesrc.tgz -C / && \
    tar -xzf /host/build/sources/netbsd-10.0-gnusrc.tgz -C /

WORKDIR /usr/src

# Map qemount architecture names to NetBSD MACHINE and MACHINE_ARCH values.
# GNU triple prefix is used for cross tools (x86_64--netbsd-strip, etc)
RUN if [ "$OUTPUT_ARCH" = "x86_64" ]; then \
        echo "amd64" > /tmp/nbarch; \
        echo "x86_64" > /tmp/nbmachinearch; \
        echo "amd64" > /tmp/nbkernarch; \
        echo "x86_64" > /tmp/nbgnutriple; \
    elif [ "$OUTPUT_ARCH" = "aarch64" ]; then \
        echo "evbarm" > /tmp/nbarch; \
        echo "aarch64" > /tmp/nbmachinearch; \
        echo "evbarm" > /tmp/nbkernarch; \
        echo "aarch64" > /tmp/nbgnutriple; \
    else \
        echo "$OUTPUT_ARCH" > /tmp/nbarch; \
        echo "$OUTPUT_ARCH" > /tmp/nbmachinearch; \
        echo "$OUTPUT_ARCH" > /tmp/nbkernarch; \
        echo "$OUTPUT_ARCH" > /tmp/nbgnutriple; \
    fi

# Build the cross-compilation toolchain and distribution. /usr/obj and
# /usr/tools use the host-backed cache while build.sh runs, then are copied
# into the image so child build stages remain self-contained.
RUN set -eu; \
    SOURCE_HASH=$(sha256sum \
        /host/build/sources/netbsd-10.0-src.tgz \
        /host/build/sources/netbsd-10.0-syssrc.tgz \
        /host/build/sources/netbsd-10.0-sharesrc.tgz \
        /host/build/sources/netbsd-10.0-gnusrc.tgz \
        | sha256sum | cut -d ' ' -f 1); \
    CACHE_DIR=/host/build/cache/netbsd/${BUILD_PLATFORM}/${OUTPUT_ARCH}/10.0; \
    CACHE_DIR=$CACHE_DIR/compiler-v1/${SOURCE_HASH}; \
    mkdir -p "$CACHE_DIR/obj" "$CACHE_DIR/tools"; \
    ln -s "$CACHE_DIR/obj" /usr/obj; \
    ln -s "$CACHE_DIR/tools" /usr/tools; \
    NBARCH=$(cat /tmp/nbarch); \
    NBMACHINEARCH=$(cat /tmp/nbmachinearch); \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j"$JOBS" \
        -m "$NBARCH" -a "$NBMACHINEARCH" tools; \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j"$JOBS" \
        -m "$NBARCH" -a "$NBMACHINEARCH" distribution; \
    rm /usr/obj /usr/tools; \
    cp -a "$CACHE_DIR/obj" /usr/obj; \
    cp -a "$CACHE_DIR/tools" /usr/tools

# Set up environment for cross-compilation
# Child images can use these for building binaries
ENV NETBSD_SRC=/usr/src
ENV NETBSD_OBJ=/usr/obj
ENV NETBSD_TOOLS=/usr/tools

# Create standard directories
RUN mkdir -p /build /outputs /host/build
WORKDIR /build
