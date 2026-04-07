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

# Source dependencies - we'll build these for each target
# glib requires: libffi, zlib, pcre2
# pixman: no deps
RUN apk add --no-cache \
    libffi-dev \
    zlib-dev \
    zlib-static \
    pcre2-dev

# Download glib and pixman sources
WORKDIR /deps
RUN curl -LO https://download.gnome.org/sources/glib/2.82/glib-2.82.4.tar.xz && \
    tar xf glib-2.82.4.tar.xz && \
    curl -LO https://cairographics.org/releases/pixman-0.44.2.tar.gz && \
    tar xf pixman-0.44.2.tar.gz && \
    curl -LO https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz && \
    tar xf libffi-3.4.6.tar.gz

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY --chmod=755 zig-wrapper.sh /zig-wrapper.sh
ENTRYPOINT ["/build.sh"]
