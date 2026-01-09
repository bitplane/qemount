ARG ARCH
FROM localhost/qemount-common-compiler-linux-6-${ARCH}
ARG ARCH

RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    linux-headers

WORKDIR /build

# Clone simple9p and libixp with the simple9p branch (has ixp_serve9conn_fd)
RUN git clone --depth 1 -b qemount-0.1 https://github.com/bitplane/simple9p.git && \
    git clone --depth 1 -b qemount-0.1 https://github.com/bitplane/libixp.git

# Build libixp
WORKDIR /build/libixp
RUN mkdir -p install/lib install/include && \
    for f in lib/libixp/*.c; do \
        echo "Compiling $f..."; \
        gcc -Iinclude -DVERSION=\"0.5\" -D_POSIX_C_SOURCE=200809L -c -o "${f%.c}.o" "$f"; \
    done && \
    ar rcs install/lib/libixp.a lib/libixp/*.o && \
    cp include/ixp.h install/include/

# Build simple9p statically linked against libixp
WORKDIR /build/simple9p
RUN LIBIXP=/build/libixp/install && \
    mkdir -p build && \
    gcc -static -I$LIBIXP/include -o build/simple9p simple9p.c path.c fs_dir.c fs_io.c fs_ops.c fs_stat.c -L$LIBIXP/lib -lixp && \
    strip build/simple9p

RUN mkdir -p /outputs/guests/linux/rootfs/${ARCH}/bin
RUN cp -v /build/simple9p/build/simple9p /outputs/guests/linux/rootfs/${ARCH}/bin/
