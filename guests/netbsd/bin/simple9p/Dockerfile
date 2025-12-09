ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH}
ARG ARCH

# Install git for cloning
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone simple9p and libixp
RUN git clone --depth 1 https://github.com/bitplane/simple9p.git && \
    git clone --depth 1 -b simple9p https://github.com/bitplane/libixp.git

# Set up cross-compilation environment
ENV NBARCH_FILE=/tmp/nbarch
ENV NBGNUTRIPLE_FILE=/tmp/nbgnutriple

# Build libixp with cross-compiler
# Skip their complex mk system and compile directly
WORKDIR /build/libixp
RUN NBARCH=$(cat /tmp/nbarch) && \
    NBGNUTRIPLE=$(cat /tmp/nbgnutriple) && \
    SYSROOT=/usr/obj/destdir.$NBARCH && \
    CC="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc" && \
    AR="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-ar" && \
    CFLAGS="--sysroot=$SYSROOT -Iinclude -DVERSION=\\\"0.5\\\" -D_POSIX_C_SOURCE=200809L" && \
    mkdir -p install/lib install/include && \
    for f in lib/libixp/*.c; do \
        echo "Compiling $f..."; \
        $CC $CFLAGS -c -o "${f%.c}.o" "$f"; \
    done && \
    $AR rcs install/lib/libixp.a lib/libixp/*.o && \
    cp include/ixp.h install/include/

# Build simple9p with cross-compiler, linking to libixp
WORKDIR /build/simple9p
RUN NBARCH=$(cat /tmp/nbarch) && \
    NBGNUTRIPLE=$(cat /tmp/nbgnutriple) && \
    SYSROOT=/usr/obj/destdir.$NBARCH && \
    CC="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc" && \
    STRIP="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip" && \
    LIBIXP=/build/libixp/install && \
    mkdir -p build && \
    $CC --sysroot=$SYSROOT -static -I$LIBIXP/include -o build/simple9p simple9p.c path.c fs_dir.c fs_io.c fs_ops.c fs_stat.c -L$LIBIXP/lib -lixp && \
    $STRIP build/simple9p

# Copy to outputs
RUN mkdir -p /outputs/guests/netbsd/rootfs/${ARCH}/bin
RUN cp -v /build/simple9p/build/simple9p /outputs/guests/netbsd/rootfs/${ARCH}/bin/
