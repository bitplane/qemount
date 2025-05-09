ARG ARCH=x86_64
FROM qemount-common-compiler-${ARCH}
ARG ARCH=x86_64

# Install additional dependencies
RUN apk add --no-cache \
    zlib-dev \
    autoconf \
    automake

# Download and extract dropbear
WORKDIR /build
RUN wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2025.87.tar.bz2
RUN tar -xf dropbear-2025.87.tar.bz2

# Configure build based on architecture
WORKDIR /build/dropbear-2025.87
RUN if [ "$ARCH" = "x86_64" ]; then \
      export CROSS_COMPILE=""; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      export CROSS_COMPILE="aarch64-none-elf-"; \
    elif [ "$ARCH" = "arm" ]; then \
      export CROSS_COMPILE="arm-none-eabi-"; \
    else \
      echo "Unsupported architecture: $ARCH"; \
      exit 1; \
    fi; \
    # Configure with static linking \
    ./configure --host=${ARCH} --disable-zlib CFLAGS="-static" LDFLAGS="-static" && \
    # Build dropbear with static linking \
    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 STATIC=1 CC=${CROSS_COMPILE}gcc -j$(nproc)

# Create output directory with architecture-specific path
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin

# Copy dropbearmulti to output and strip it
RUN cp -v /build/dropbear-2025.87/dropbearmulti /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/ && \
    strip /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/dropbearmulti
