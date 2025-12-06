ARG ARCH

FROM docker.io/library/debian:bookworm-slim AS builder
ARG ARCH

# Install build dependencies for NetBSD build.sh
# Using Debian because musl libc (Alpine) has conflicts with old texinfo code
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    curl \
    ca-certificates \
    tar \
    xz-utils \
    gzip \
    bzip2 \
    zlib1g-dev \
    libncurses-dev \
    coreutils \
    findutils \
    diffutils \
    patch \
    gawk \
    sed \
    grep \
    texinfo \
    groff \
    flex \
    bison \
    perl \
    python3 \
    autoconf \
    automake \
    libtool \
    gettext \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download NetBSD 10.0 source
# src.tgz = base source, syssrc.tgz = kernel, sharesrc.tgz = share/mk
# gnusrc.tgz = external/gpl3 (binutils including mdsetimage)
RUN curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/src.tgz && \
    curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/syssrc.tgz && \
    curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/sharesrc.tgz && \
    curl -LO https://ftp.netbsd.org/pub/NetBSD/NetBSD-10.0/source/sets/gnusrc.tgz

# Extract source
RUN mkdir -p /usr/src && \
    tar -xzf src.tgz -C / && \
    tar -xzf syssrc.tgz -C / && \
    tar -xzf sharesrc.tgz -C / && \
    tar -xzf gnusrc.tgz -C /

WORKDIR /usr/src

# Map architecture names
# ARCH comes in as x86_64, NetBSD uses amd64
# Also store the kernel arch directory name (different for some archs)
RUN if [ "$ARCH" = "x86_64" ]; then \
        echo "amd64" > /tmp/nbarch; \
        echo "amd64" > /tmp/nbkernarch; \
    elif [ "$ARCH" = "aarch64" ]; then \
        echo "evbarm" > /tmp/nbarch; \
        echo "evbarm" > /tmp/nbkernarch; \
    else \
        echo "$ARCH" > /tmp/nbarch; \
        echo "$ARCH" > /tmp/nbkernarch; \
    fi

# Build cross-compilation toolchain
# This takes 30-60 minutes on first build
RUN NBARCH=$(cat /tmp/nbarch) && \
    ./build.sh -O /usr/obj -T /usr/tools -U -j$(nproc) -m $NBARCH tools

# Copy custom kernel config (to temp location, then move to arch-specific dir)
COPY kernel/QEMOUNT /tmp/QEMOUNT
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    cp /tmp/QEMOUNT /usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT

# Build the kernel
RUN NBARCH=$(cat /tmp/nbarch) && \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j$(nproc) -m $NBARCH kernel=QEMOUNT

# Build a minimal distribution for ramdisk files
RUN NBARCH=$(cat /tmp/nbarch) && \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j$(nproc) -m $NBARCH distribution

# Create ramdisk with essential binaries
# Note: avoid bash brace expansion - Debian uses dash which doesn't support it
RUN mkdir -p /ramdisk/bin /ramdisk/sbin /ramdisk/dev /ramdisk/etc /ramdisk/mnt /ramdisk/tmp /ramdisk/proc

# Copy essential binaries from the built distribution
RUN NBARCH=$(cat /tmp/nbarch) && \
    DESTDIR=/usr/obj/destdir.$NBARCH && \
    cp $DESTDIR/bin/sh /ramdisk/bin/ && \
    cp $DESTDIR/bin/ls /ramdisk/bin/ && \
    cp $DESTDIR/bin/cat /ramdisk/bin/ && \
    cp $DESTDIR/bin/echo /ramdisk/bin/ && \
    cp $DESTDIR/bin/mkdir /ramdisk/bin/ && \
    cp $DESTDIR/bin/sleep /ramdisk/bin/ && \
    cp $DESTDIR/sbin/mount /ramdisk/sbin/ && \
    cp $DESTDIR/sbin/umount /ramdisk/sbin/ && \
    cp $DESTDIR/sbin/init /ramdisk/sbin/init.real || true

# Create a simple init script
RUN echo '#!/bin/sh' > /ramdisk/sbin/init && \
    echo 'export PATH=/bin:/sbin' >> /ramdisk/sbin/init && \
    echo 'echo "NetBSD qemount guest starting..."' >> /ramdisk/sbin/init && \
    echo 'exec /bin/sh' >> /ramdisk/sbin/init && \
    chmod +x /ramdisk/sbin/init

# Create minimal /etc files
RUN echo 'root:x:0:0:root:/:/bin/sh' > /ramdisk/etc/passwd && \
    echo 'root:x:0:' > /ramdisk/etc/group

# Create ramdisk filesystem image (8MB)
# nbmakefs is the cross-tool built by build.sh
RUN /usr/tools/bin/nbmakefs -s 8m -t ffs /ramdisk.fs /ramdisk

# Embed ramdisk into kernel using mdsetimage
# Note: mdsetimage is built in obj/tools/, not tools/bin/
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    KERNEL=/usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd && \
    /usr/obj/tools/mdsetimage/mdsetimage -v $KERNEL /ramdisk.fs

# Create output directory and copy kernel
RUN mkdir -p /outputs/guests/netbsd/10.0/${ARCH}
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    cp /usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd \
       /outputs/guests/netbsd/10.0/${ARCH}/netbsd

# Copy deploy script from common pattern
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
