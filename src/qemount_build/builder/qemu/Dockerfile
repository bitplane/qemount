FROM alpine:3.23

# Build tools
RUN apk add --no-cache \
    bash \
    curl \
    xz \
    tar \
    git \
    python3 \
    py3-pip \
    meson \
    ninja \
    pkgconf \
    make \
    perl \
    binutils

# Install zig via pip (cross-compiler toolchain)
RUN pip install --break-system-packages ziglang

# Host zlib for build tools (cross-compiled deps come from sources)
RUN apk add --no-cache \
    zlib-dev \
    zlib-static

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY --chmod=755 zig-wrapper.sh /zig-wrapper.sh
ENTRYPOINT ["/build.sh"]
