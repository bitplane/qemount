ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

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

WORKDIR /build/linux-6.11


RUN set -x; \
    KERNEL_ARCH=$ARCH; \
    [ "$ARCH" = "aarch64" ] && KERNEL_ARCH=arm64; \
    make ARCH=$KERNEL_ARCH defconfig && \
    ./scripts/kconfig/merge_config.sh -m .config kernel.config filesystems.config && \
    yes "" | make ARCH=$KERNEL_ARCH oldconfig && \
    make ARCH=$KERNEL_ARCH -j$(nproc)

# Create output directory
RUN mkdir -p /outputs/guests/linux/6.11/${ARCH}

# Copy kernel image to output
RUN if [ "$ARCH" = "x86_64" ]; then \
      cp -v arch/x86_64/boot/bzImage /outputs/guests/linux/6.11/${ARCH}/kernel; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      cp -v arch/arm64/boot/Image.gz /outputs/guests/linux/6.11/${ARCH}/kernel; \
    elif [ "$ARCH" = "arm" ]; then \
      cp -v arch/arm/boot/zImage /outputs/guests/linux/6.11/${ARCH}/kernel; \
    else \
      echo "Unsupported architecture: $ARCH"; \
      exit 1; \
    fi

# Copy metadata
RUN touch /outputs/guests/linux/6.11/${ARCH}/meta.conf
