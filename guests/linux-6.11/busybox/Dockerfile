ARG ARCH
FROM localhost/qemount-common-compiler-${ARCH}
ARG ARCH

RUN apk add python3

# Download and extract BusyBox
WORKDIR /build
RUN wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
RUN tar -xf busybox-1.36.1.tar.bz2

COPY *.config /build/
COPY *.py /usr/local/bin/
COPY *.sh /usr/local/bin/

WORKDIR /build/busybox-1.36.1

# Configure build - use compiler from parent image
RUN make defconfig && \
    # Create architecture-specific config symlink \
    /usr/local/bin/ensure_link.sh /build/busybox.${BUSYBOX_ARCH}.config /build/busybox.config && \
    # Merge configs \
    python3 /usr/local/bin/merge_config.py .config /build/busybox.config .config && \
    # Accept defaults for any new options \
    yes "" | make oldconfig || true && \
    # Build busybox with our cross compiler \
    make -j$(nproc) CC=$CC CONFIG_STATIC=y

# Create output directory, copy, link files
RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin && \
    cp -v /build/busybox-1.36.1/busybox /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/ && \
    cd /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/ && \
    for f in $(./busybox --list); do \
        ln -s ./busybox "$f"; \
    done
