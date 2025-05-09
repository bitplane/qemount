ARG ARCH=x86_64
FROM qemount-common-compiler-${ARCH}
ARG ARCH

# Install additional dependencies including static fuse library
RUN apk add --no-cache \
    git \
    meson \
    cmake \
    fuse-dev \
    fuse-static \
    linux-headers

# Clone and build 9pfuse
RUN mkdir -p /build
WORKDIR /build
RUN git clone https://github.com/aperezdc/9pfuse.git /build/9pfuse

WORKDIR /build/9pfuse

# Configure meson to build statically
RUN meson setup build \
    --default-library=static \
    --prefer-static \
    -Dc_link_args="-static" && \
    meson compile -C build

# Strip and copy the binary to outputs
RUN mkdir -p /outputs/clients/linux-fuse/${ARCH}/bin && \
    cp -v build/9pfuse /outputs/clients/linux-fuse/${ARCH}/bin/ && \
    strip /outputs/clients/linux-fuse/${ARCH}/bin/9pfuse