FROM alpine:latest

# Runtime tools
RUN apk add --no-cache \
    bash tar jq \
    qemu-system-x86_64 qemu-system-aarch64 \
    e2fsprogs e2fsprogs-extra \
    xfsprogs jfsutils f2fs-tools hfsprogs \
    udftools nilfs-utils exfatprogs ntfs-3g-progs \
    reiserfsprogs \
    util-linux

# Build bcachefs-tools from source
RUN apk add --no-cache --virtual .build-deps \
    build-base git curl coreutils \
    rust cargo \
    libaio-dev keyutils-dev lz4-dev \
    linux-headers eudev-dev zlib-dev \
    zstd-dev userspace-rcu-dev libsodium-dev \
    util-linux-dev clang-dev python3 py3-docutils \
    && cd /tmp \
    && curl -L https://github.com/koverstreet/bcachefs-tools/archive/refs/tags/v1.20.0.tar.gz | tar xz \
    && cd bcachefs-tools-1.20.0 \
    && make -j$(nproc) NO_VALGRIND=1 \
    && make install \
    && cd / \
    && rm -rf /tmp/bcachefs-tools-1.20.0 \
    && apk del .build-deps \
    && apk add --no-cache libaio keyutils-libs lz4-libs zstd-libs userspace-rcu libsodium eudev-libs

# Build mkfs.sysv from source
COPY mkfs.sysv.c /tmp/mkfs.sysv.c
RUN apk add --no-cache --virtual .sysv-deps gcc musl-dev \
    && gcc -o /usr/local/bin/mkfs.sysv /tmp/mkfs.sysv.c \
    && rm /tmp/mkfs.sysv.c \
    && apk del .sysv-deps

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
