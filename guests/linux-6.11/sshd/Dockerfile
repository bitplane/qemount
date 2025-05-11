ARG ARCH
FROM qemount-common-compiler-${ARCH}
ARG ARCH

# Install additional dependencies
RUN apk add --no-cache \
    zlib-dev \
    autoconf \
    automake

# Download and extract dropbear
WORKDIR /build
RUN wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.87.tar.bz2
RUN tar -xf dropbear-2025.87.tar.bz2

WORKDIR /build/dropbear-2025.87

# Configure with our cross compiler
RUN ./configure \
    --host=${ARCH}-linux-musl \
    --disable-zlib \
    CC=$CC \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# Build dropbear with static linking
RUN make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 STATIC=1 -j$(nproc)

# Create output directory
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin

# Copy dropbearmulti to output and strip it
RUN cp -v /build/dropbear-2025.87/dropbearmulti /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/ && \
    ${CC%-gcc}-strip /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/dropbearmulti || true
