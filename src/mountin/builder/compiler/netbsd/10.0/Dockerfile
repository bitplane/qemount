ARG OUTPUT_ARCH
ARG BUILD_PLATFORM
ARG JOBS=1
ARG MOUNTIN_CACHE_DIR

FROM debian:bookworm-slim AS base
ARG OUTPUT_ARCH
ARG BUILD_PLATFORM
ARG JOBS=1
ARG MOUNTIN_CACHE_DIR

# Install build dependencies for NetBSD build.sh
# Using Debian because musl libc (Alpine) has conflicts with old texinfo code
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
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

FROM base AS builder
ARG OUTPUT_ARCH
ARG BUILD_PLATFORM
ARG JOBS=1
ARG MOUNTIN_CACHE_DIR

WORKDIR /build

# Extract source from mounted build_requires
RUN mkdir -p /usr/src && \
    tar -xzf /host/build/sources/netbsd-10.0-src.tgz -C / && \
    tar -xzf /host/build/sources/netbsd-10.0-syssrc.tgz -C / && \
    tar -xzf /host/build/sources/netbsd-10.0-sharesrc.tgz -C / && \
    tar -xzf /host/build/sources/netbsd-10.0-gnusrc.tgz -C / && \
    grep -qx 'GCC_LANGUAGES=c c++ objc' /usr/src/tools/gcc/Makefile && \
    sed -i \
        -e 's/^GCC_LANGUAGES=c c++ objc$/GCC_LANGUAGES=c/' \
        -e 's/^MULTILIB_ARGS= --enable-multilib$/MULTILIB_ARGS= --disable-multilib/' \
        /usr/src/tools/gcc/Makefile

WORKDIR /usr/src

# Map mountin architecture names to NetBSD MACHINE and MACHINE_ARCH values.
# GNU triple prefix is used for cross tools (x86_64--netbsd-strip, etc)
RUN if [ "$OUTPUT_ARCH" = "x86_64" ]; then \
        echo "amd64" > /tmp/nbarch; \
        echo "x86_64" > /tmp/nbmachinearch; \
        echo "amd64" > /tmp/nbkernarch; \
        echo "x86_64" > /tmp/nbgnutriple; \
    elif [ "$OUTPUT_ARCH" = "aarch64" ]; then \
        echo "evbarm" > /tmp/nbarch; \
        echo "aarch64" > /tmp/nbmachinearch; \
        echo "evbarm" > /tmp/nbkernarch; \
        echo "aarch64" > /tmp/nbgnutriple; \
    else \
        echo "$OUTPUT_ARCH" > /tmp/nbarch; \
        echo "$OUTPUT_ARCH" > /tmp/nbmachinearch; \
        echo "$OUTPUT_ARCH" > /tmp/nbkernarch; \
        echo "$OUTPUT_ARCH" > /tmp/nbgnutriple; \
    fi

# Build the C-only cross-compilation toolchain and the target headers/libraries.
# A complete NetBSD distribution builds thousands of programs which are never
# used by mountin; the native make targets below are the supported foundation
# for building selected target programs later.
RUN set -eu; \
    CACHE_DIR=$MOUNTIN_CACHE_DIR; \
    mkdir -p "$CACHE_DIR/obj" "$CACHE_DIR/tools"; \
    ln -s "$CACHE_DIR/obj" /usr/obj; \
    ln -s "$CACHE_DIR/tools" /usr/tools; \
    NBARCH=$(cat /tmp/nbarch); \
    NBMACHINEARCH=$(cat /tmp/nbmachinearch); \
    ./build.sh -O /usr/obj -T /usr/tools -U -u -j"$JOBS" \
        -m "$NBARCH" -a "$NBMACHINEARCH" \
        -V MKCOMPAT=no -V MKCTF=no -V MKDEBUG=no -V MKDEBUGLIB=no \
        -V MKHTML=no -V MKINFO=no -V MKMAN=no -V MKNLS=no \
        -V MKPIC=no -V MKPROFILE=no -V MKTESTS=no -V MKX11=no tools; \
    NBMAKE="$CACHE_DIR/tools/bin/nbmake-$NBARCH"; \
    "$NBMAKE" -C /usr/src obj do-distrib-dirs includes; \
    "$NBMAKE" -C /usr/src/external/gpl3/gcc/lib/libgcc obj; \
    "$NBMAKE" -C /usr/src/external/gpl3/gcc/lib/libgcc dependall; \
    "$NBMAKE" -C /usr/src/external/gpl3/gcc/lib/libgcc install; \
    for directory in \
        lib/csu \
        lib/libc \
        lib/libm \
        lib/libprop \
        lib/libterminfo \
        lib/libedit \
        lib/libutil \
        lib/libpthread; \
    do \
        "$NBMAKE" -C "/usr/src/$directory" obj; \
        "$NBMAKE" -C "/usr/src/$directory" dependall; \
        "$NBMAKE" -C "/usr/src/$directory" install; \
    done; \
    if [ "$NBARCH" = amd64 ]; then \
        "$NBMAKE" -C /usr/src/sys/arch/i386/stand/boot obj; \
        "$NBMAKE" -C /usr/src/sys/arch/i386/stand/boot dependall; \
        "$NBMAKE" -C /usr/src/sys/arch/i386/stand/boot install; \
        "$NBMAKE" -C /usr/src/sys/arch/i386/stand/bootxx/bootxx_ffsv1 \
            obj; \
        "$NBMAKE" -C /usr/src/sys/arch/i386/stand/bootxx/bootxx_ffsv1 \
            dependall; \
        "$NBMAKE" -C /usr/src/sys/arch/i386/stand/bootxx/bootxx_ffsv1 \
            install; \
    fi; \
    rm /usr/obj /usr/tools; \
    mkdir -p /opt/netbsd/obj; \
    cp -a "$CACHE_DIR/tools" /opt/netbsd/tools; \
    DESTDIR="$CACHE_DIR/obj/destdir.$NBARCH"; \
    IMAGE_DESTDIR="/opt/netbsd/obj/destdir.$NBARCH"; \
    mkdir -p "$IMAGE_DESTDIR/usr"; \
    cp -a "$DESTDIR/lib" "$IMAGE_DESTDIR/"; \
    cp -a "$DESTDIR/usr/include" "$DESTDIR/usr/lib" "$IMAGE_DESTDIR/usr/"; \
    if [ -d "$DESTDIR/usr/mdec" ]; then \
        cp -a "$DESTDIR/usr/mdec" "$IMAGE_DESTDIR/usr/"; \
    fi; \
    rm -rf "$IMAGE_DESTDIR/lib/i386" "$IMAGE_DESTDIR/usr/lib/i386"

FROM base
ARG OUTPUT_ARCH

COPY --from=builder /tmp/nbarch /tmp/nbarch
COPY --from=builder /tmp/nbmachinearch /tmp/nbmachinearch
COPY --from=builder /tmp/nbkernarch /tmp/nbkernarch
COPY --from=builder /tmp/nbgnutriple /tmp/nbgnutriple
COPY --from=builder /opt/netbsd/tools /usr/tools
COPY --from=builder /opt/netbsd/obj /usr/obj
COPY --from=builder /usr/src/share/mk /usr/src/share/mk
COPY --chmod=755 cc.sh /usr/local/bin/netbsd-cc

# Give consumers an architecture-independent compiler interface. The target
# mapping remains an implementation detail of this image.
RUN set -eu; \
    NBARCH=$(cat /tmp/nbarch); \
    NBGNUTRIPLE=$(cat /tmp/nbgnutriple); \
    mkdir -p /usr/local/libexec /opt/netbsd; \
    ln -s "/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc" \
        /usr/local/libexec/netbsd-gcc; \
    ln -s "/usr/tools/bin/${NBGNUTRIPLE}--netbsd-ar" \
        /usr/local/bin/netbsd-ar; \
    ln -s "/usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip" \
        /usr/local/bin/netbsd-strip; \
    ln -s "/usr/obj/destdir.${NBARCH}" /opt/netbsd/sysroot

ENV NETBSD_OBJ=/usr/obj \
    NETBSD_TOOLS=/usr/tools \
    NETBSD_SYSROOT=/opt/netbsd/sysroot \
    CC=netbsd-cc \
    AR=netbsd-ar \
    STRIP=netbsd-strip

# Create standard directories
RUN mkdir -p /build /outputs /host/build
WORKDIR /build
