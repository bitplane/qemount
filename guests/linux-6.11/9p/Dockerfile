FROM qemount-common-compiler-${ARCH}
ARG ARCH
# Install additional dependencies
RUN apk add --no-cache \
    libtool \
    autoconf \
    make \
    gcc \
    file \
    patch

# Download and extract Plan 9 source containing u9fs
RUN mkdir -p /build
WORKDIR /build
RUN git clone https://github.com/unofficial-mirror/u9fs.git

# Try to build u9fs
WORKDIR /build/u9fs
ADD authrhosts.c /build/u9fs/authrhosts.c

# Force static linking by modifying the makefile
RUN sed -i 's/^CFLAGS=/CFLAGS=-static /' makefile && \
    sed -i 's/^LDFLAGS=/LDFLAGS=-static /' makefile

# Build with static linking
RUN CFLAGS="-static" LDFLAGS="-static" make clean || true
RUN CFLAGS="-static" LDFLAGS="-static" make

# Verify the build succeeded and is statically linked
RUN test -f u9fs && file u9fs | grep -q "statically linked"

# Create output directory and copy with stripping
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin && \
    cp -v u9fs /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/u9fs && \
    strip /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/u9fs
