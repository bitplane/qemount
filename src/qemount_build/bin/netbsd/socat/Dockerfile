ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH}
ARG ARCH

# Install wget for downloading
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

# Download and extract socat
WORKDIR /build
RUN wget http://www.dest-unreach.org/socat/download/socat-1.7.4.4.tar.gz && \
    tar -xzf socat-1.7.4.4.tar.gz

WORKDIR /build/socat-1.7.4.4

# Cross-compile for NetBSD
# socat uses autoconf, so we pass --host for cross-compilation
RUN NBARCH=$(cat /tmp/nbarch) && \
    NBGNUTRIPLE=$(cat /tmp/nbgnutriple) && \
    SYSROOT=/usr/obj/destdir.$NBARCH && \
    CC="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc" && \
    CFLAGS="--sysroot=$SYSROOT" && \
    LDFLAGS="--sysroot=$SYSROOT -static" && \
    ./configure \
        --host=${NBGNUTRIPLE}--netbsd \
        CC="$CC" \
        CFLAGS="$CFLAGS" \
        LDFLAGS="$LDFLAGS" \
        --disable-openssl \
        --disable-readline

# Build socat
RUN make -j$(nproc)

# Strip the binary
RUN NBGNUTRIPLE=$(cat /tmp/nbgnutriple) && \
    /usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip socat || true

# Copy to outputs
RUN mkdir -p /outputs/guests/netbsd/rootfs/${ARCH}/bin
RUN cp -v socat /outputs/guests/netbsd/rootfs/${ARCH}/bin/
