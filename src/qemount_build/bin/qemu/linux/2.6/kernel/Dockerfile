ARG ARCH

# Download kernel source using modern image with working TLS
FROM docker.io/library/alpine:latest AS downloader
RUN apk add --no-cache wget
RUN wget -O /linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v2.6/linux-2.6.39.4.tar.xz

ARG ARCH
FROM localhost/qemount-common-compiler-linux-2-${ARCH}
ARG ARCH

# Copy and extract Linux kernel 2.6.39.4 (final 2.6 release)
WORKDIR /build
COPY --from=downloader /linux.tar.xz /build/
RUN tar -xf linux.tar.xz

# Copy config files
COPY *.config /build/linux-2.6.39.4/

WORKDIR /build/linux-2.6.39.4

# Build kernel - 2.6 only supports x86 (i386/x86_64)
# Note: merge_config.sh doesn't exist in 2.6.39, so we cat configs and use oldconfig
RUN set -x; \
    if [ "$ARCH" = "x86_64" ]; then \
        KERNEL_ARCH=x86_64; \
    elif [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ]; then \
        KERNEL_ARCH=i386; \
    else \
        echo "Unsupported architecture for 2.6 kernel: $ARCH"; \
        exit 1; \
    fi; \
    make ARCH=$KERNEL_ARCH defconfig && \
    cat kernel.config filesystems.config >> .config && \
    yes "" | make ARCH=$KERNEL_ARCH oldconfig && \
    make ARCH=$KERNEL_ARCH -j4

# Create output directory
RUN mkdir -p /outputs/guests/linux/2.6/${ARCH}

# Copy kernel image to output
RUN if [ "$ARCH" = "x86_64" ]; then \
      cp -v arch/x86_64/boot/bzImage /outputs/guests/linux/2.6/${ARCH}/kernel; \
    elif [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ]; then \
      cp -v arch/x86/boot/bzImage /outputs/guests/linux/2.6/${ARCH}/kernel; \
    fi

# Copy metadata
RUN touch /outputs/guests/linux/2.6/${ARCH}/meta.conf
