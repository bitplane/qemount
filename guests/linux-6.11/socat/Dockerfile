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

# Configure for static build with our cross compiler
RUN ./configure \
    --host=${ARCH}-linux-musl \
    --enable-static \
    --disable-shared \
    CC=$CC \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# Build socat
RUN make -j$(nproc)

# Strip the binary
RUN ${CC%-gcc}-strip socat || true

# Create output directory and copy binary
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin
RUN cp -v socat /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/
