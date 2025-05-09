ARG ARCH=x86_64
FROM qemount-common-compiler-${ARCH}
ARG ARCH=x86_64

# Download and extract BusyBox
WORKDIR /build
RUN wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
RUN tar -xf busybox-1.36.1.tar.bz2

# Copy config files and scripts
COPY busybox.config /build/busybox.config
COPY merge_config.py /build/merge_config.py
COPY ensure_link.sh /build/ensure_link.sh

# Configure build based on architecture
WORKDIR /build/busybox-1.36.1
RUN if [ "$ARCH" = "x86_64" ]; then \
      export BUSYBOX_ARCH=x86_64; \
      export CROSS_COMPILE=""; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      export BUSYBOX_ARCH=aarch64; \
      export CROSS_COMPILE="aarch64-none-elf-"; \
    elif [ "$ARCH" = "arm" ]; then \
      export BUSYBOX_ARCH=arm; \
      export CROSS_COMPILE="arm-none-eabi-"; \
    else \
      echo "Unsupported architecture: $ARCH"; \
      exit 1; \
    fi; \
    # Create default config \
    make defconfig && \
    # Create architecture-specific config symlink \
    /build/ensure_link.sh /build/busybox.${BUSYBOX_ARCH}.config /build/busybox.config && \
    # Merge configs \
    python3 /build/merge_config.py .config /build/busybox.config .config && \
    # Accept defaults for any new options \
    yes "" | make oldconfig || true && \
    # Build busybox statically \
    make -j$(nproc) CROSS_COMPILE=$CROSS_COMPILE CONFIG_STATIC=y

# Create output directory structure matching the outputs.txt
# This path should match exactly what's in outputs.txt
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin

# Copy busybox to output location
RUN cp -v /build/busybox-1.36.1/busybox /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/
