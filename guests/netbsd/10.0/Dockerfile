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
# GNU triple prefix is used for cross tools (x86_64--netbsd-strip, etc)
RUN if [ "$ARCH" = "x86_64" ]; then \
        echo "amd64" > /tmp/nbarch; \
        echo "amd64" > /tmp/nbkernarch; \
        echo "x86_64" > /tmp/nbgnutriple; \
    elif [ "$ARCH" = "aarch64" ]; then \
        echo "evbarm" > /tmp/nbarch; \
        echo "evbarm" > /tmp/nbkernarch; \
        echo "aarch64" > /tmp/nbgnutriple; \
    else \
        echo "$ARCH" > /tmp/nbarch; \
        echo "$ARCH" > /tmp/nbkernarch; \
        echo "$ARCH" > /tmp/nbgnutriple; \
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

# Build ramdisk with statically-linked rescue binaries
COPY --chmod=755 ramdisk/build.sh /tmp/build-ramdisk.sh
RUN NBARCH=$(cat /tmp/nbarch) && \
    /tmp/build-ramdisk.sh /usr/obj/destdir.$NBARCH /ramdisk

# Copy init scripts and etc files
COPY --chmod=755 ramdisk/sbin/init /ramdisk/sbin/init
COPY --chmod=755 ramdisk/init.sh /ramdisk/init.sh
COPY --chmod=755 ramdisk/init.9p /ramdisk/init.9p
COPY ramdisk/etc/passwd /ramdisk/etc/passwd
COPY ramdisk/etc/group /ramdisk/etc/group

# Create ramdisk filesystem image (12MB for rescue binary)
# Use FFS v1 for compatibility with memory disk boot
RUN /usr/tools/bin/nbmakefs -s 12m -t ffs -o version=1 /ramdisk.fs /ramdisk

# Embed ramdisk into kernel using mdsetimage
# Must use unstripped kernel (netbsd.gdb) for mdsetimage to find symbols
RUN NBKERNARCH=$(cat /tmp/nbkernarch) && \
    KERNEL=/usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb && \
    /usr/obj/tools/mdsetimage/mdsetimage -v $KERNEL /ramdisk.fs

# Strip the kernel after embedding ramdisk (reduces ~180MB to ~20MB)
RUN NBGNUTRIPLE=$(cat /tmp/nbgnutriple) && \
    NBKERNARCH=$(cat /tmp/nbkernarch) && \
    KERNEL=/usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb && \
    /usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip -o /netbsd.stripped $KERNEL

# Copy boot config files from source
COPY boot.cfg /tmp/boot.cfg
COPY disklabel.proto /disklabel.proto

# Create a bootable disk image manually
# mkimage has a bug where it looks for /usr/mdec/boot instead of $DESTDIR/usr/mdec/boot
RUN NBARCH=$(cat /tmp/nbarch) && \
    DESTDIR=/usr/obj/destdir.$NBARCH && \
    TOOLDIR=/usr/tools && \
    mkdir -p /bootfs && \
    cp /netbsd.stripped /bootfs/netbsd && \
    cp $DESTDIR/usr/mdec/boot /bootfs/boot && \
    cp /tmp/boot.cfg /bootfs/boot.cfg && \
    $TOOLDIR/bin/nbmakefs -s 48m -t ffs -o version=1 /boot.img /bootfs && \
    $TOOLDIR/bin/nbdisklabel -M $NBARCH -R -F /boot.img /disklabel.proto && \
    $TOOLDIR/bin/nbinstallboot -m $NBARCH -o timeout=0 /boot.img $DESTDIR/usr/mdec/bootxx_ffsv1

# Create output directory and copy boot image
RUN mkdir -p /outputs/guests/netbsd/10.0/${ARCH}
RUN cp /boot.img /outputs/guests/netbsd/10.0/${ARCH}/boot.img

# Also copy the stripped kernel
RUN cp /netbsd.stripped /outputs/guests/netbsd/10.0/${ARCH}/netbsd

# Copy deploy script from common pattern
COPY --chmod=755 deploy.sh /usr/local/bin/deploy.sh
ENTRYPOINT ["/usr/local/bin/deploy.sh"]
