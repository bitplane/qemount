ARG ARCH=x86_64
FROM qemount-common-compiler-${ARCH}
ARG ARCH=x86_64

# Install additional dependencies for kernel build
RUN apk add --no-cache \
    bc \
    bison \
    flex \
    elfutils-dev \
    openssl-dev \
    perl \
    python3 \
    ncurses-dev \
    xz \
    rsync \
    bash

# Download and extract Linux kernel
WORKDIR /build
RUN wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.11.tar.xz
RUN tar -xf linux-6.11.tar.xz

# Copy config files
COPY *.config /build/linux-6.11/

# Move to kernel source directory
WORKDIR /build/linux-6.11

# Set architecture-specific variables
RUN if [ "$ARCH" = "x86_64" ]; then \
      export KERNEL_ARCH=x86_64; \
      export IMAGE_NAME=bzImage; \
      export CROSS_COMPILE=""; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      export KERNEL_ARCH=arm64; \
      export IMAGE_NAME=Image.gz; \
      export CROSS_COMPILE="aarch64-none-elf-"; \
    elif [ "$ARCH" = "arm" ]; then \
      export KERNEL_ARCH=arm; \
      export IMAGE_NAME=zImage; \
      export CROSS_COMPILE="arm-none-eabi-"; \
    else \
      echo "Unsupported architecture: $ARCH"; \
      exit 1; \
    fi; \
    # Merge appropriate config files \
    CONF_TO_USE="kernel.$KERNEL_ARCH.config"; \
    if [ ! -f "$CONF_TO_USE" ]; then \
      CONF_TO_USE="kernel.config"; \
    fi; \
    echo "Using config file: $CONF_TO_USE"; \
    make ARCH=$KERNEL_ARCH defconfig && \
    ./scripts/kconfig/merge_config.sh -m .config $CONF_TO_USE && \
    ./scripts/kconfig/merge_config.sh -m .config filesystems.config && \
    yes "" | make ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE oldconfig && \
    # Build the kernel \
    make -j$(nproc) ARCH=$KERNEL_ARCH CROSS_COMPILE=$CROSS_COMPILE $IMAGE_NAME

# Create output directory with architecture-specific path
RUN mkdir -p /outputs/guests/linux-6.11-${ARCH}

# Copy kernel image to output (with generalized path logic)
RUN if [ "$ARCH" = "x86_64" ]; then \
      cp -v arch/x86_64/boot/bzImage /outputs/guests/linux-6.11-${ARCH}/kernel; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      cp -v arch/arm64/boot/Image.gz /outputs/guests/linux-6.11-${ARCH}/kernel; \
    elif [ "$ARCH" = "arm" ]; then \
      cp -v arch/arm/boot/zImage /outputs/guests/linux-6.11-${ARCH}/kernel; \
    else \
      echo "Unsupported architecture: $ARCH"; \
      exit 1; \
    fi

# Copy metadata
RUN touch /outputs/guests/linux-6.11-${ARCH}/meta.conf
