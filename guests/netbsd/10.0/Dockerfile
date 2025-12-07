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
RUN mkdir -p /ramdisk/bin /ramdisk/sbin /ramdisk/dev /ramdisk/etc /ramdisk/mnt /ramdisk/tmp /ramdisk/proc /ramdisk/kern

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
    cp $DESTDIR/sbin/halt /ramdisk/sbin/ && \
    cp $DESTDIR/sbin/init /ramdisk/sbin/init.real || true

# Copy init scripts and etc files from source
COPY --chmod=755 ramdisk/sbin/init /ramdisk/sbin/init
COPY --chmod=755 ramdisk/init.sh /ramdisk/init.sh
COPY --chmod=755 ramdisk/init.9p /ramdisk/init.9p
COPY ramdisk/etc/passwd /ramdisk/etc/passwd
COPY ramdisk/etc/group /ramdisk/etc/group

# Create ramdisk filesystem image (8MB)
# nbmakefs is the cross-tool built by build.sh
# Use FFS v1 for compatibility with memory disk boot
RUN /usr/tools/bin/nbmakefs -s 8m -t ffs -o version=1 /ramdisk.fs /ramdisk

# Embed ramdisk into kernel using mdsetimage
# Use netbsd.gdb (unstripped) - keeps symbols, runs fine, easier to debug
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    KERNEL=/usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb && \
    /usr/obj/tools/mdsetimage/mdsetimage -v $KERNEL /ramdisk.fs

# Copy boot config files from source
COPY boot.cfg /tmp/boot.cfg
COPY disklabel.proto /disklabel.proto

# Create a bootable disk image manually
# mkimage has a bug where it looks for /usr/mdec/boot instead of $DESTDIR/usr/mdec/boot
RUN NBARCH=$(cat /tmp/nbarch) && \
    NBKERNARCH=$(cat /tmp/nbkernarch) && \
    DESTDIR=/usr/obj/destdir.$NBARCH && \
    KERNEL=/usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb && \
    TOOLDIR=/usr/tools && \
    mkdir -p /bootfs && \
    cp $KERNEL /bootfs/netbsd && \
    cp $DESTDIR/usr/mdec/boot /bootfs/boot && \
    cp /tmp/boot.cfg /bootfs/boot.cfg && \
    $TOOLDIR/bin/nbmakefs -s 256m -t ffs -o version=1 /boot.img /bootfs && \
    $TOOLDIR/bin/nbdisklabel -M $NBARCH -R -F /boot.img /disklabel.proto && \
    $TOOLDIR/bin/nbinstallboot -m $NBARCH -o timeout=0 /boot.img $DESTDIR/usr/mdec/bootxx_ffsv1

# Create output directory and copy boot image
RUN mkdir -p /outputs/guests/netbsd/10.0/${ARCH}
RUN cp /boot.img /outputs/guests/netbsd/10.0/${ARCH}/boot.img

# Also copy the raw kernel for reference
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    cp /usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb \
       /outputs/guests/netbsd/10.0/${ARCH}/netbsd

# Copy deploy script from common pattern
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
