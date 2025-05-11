ARG ARCH
FROM qemount-common-compiler-${ARCH}
ARG ARCH

# Install additional dependencies for socat
RUN apk add --no-cache \
    linux-headers \
    readline-dev \
    openssl-dev

# Download and extract socat
WORKDIR /build
RUN wget http://www.dest-unreach.org/socat/download/socat-1.7.4.4.tar.gz
RUN tar -xzf socat-1.7.4.4.tar.gz

WORKDIR /build/socat-1.7.4.4

RUN ./configure \
    --enable-static \
    --disable-shared

# Build socat
RUN make -j$(nproc) && \
    strip socat || true

# Create output directory and copy binary
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin
RUN cp -v socat /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/
