FROM alpine:latest
ARG HOST_ARCH

# Runtime tools
RUN apk add --no-cache \
    bash tar xz jq findutils \
    qemu-system-x86_64 qemu-system-aarch64 \
    e2fsprogs e2fsprogs-extra \
    xfsprogs jfsutils f2fs-tools hfsprogs \
    udftools nilfs-utils exfatprogs ntfs-3g-progs \
    util-linux

# Build dependencies for bcachefs-tools
RUN apk add --no-cache \
    build-base \
    rust cargo \
    libaio-dev keyutils-dev lz4-dev \
    linux-headers eudev-dev zlib-dev \
    zstd-dev userspace-rcu-dev libsodium-dev \
    util-linux-dev clang-dev python3 py3-docutils

# Build bcachefs-tools from mounted source
RUN cd /tmp && \
    tar xzf /host/build/sources/bcachefs-tools-1.20.0.tar.gz && \
    cd bcachefs-tools-1.20.0 && \
    make -j$(nproc) NO_VALGRIND=1 && \
    make install && \
    cd / && rm -rf /tmp/bcachefs-tools-1.20.0

# Copy pre-built static binaries
RUN cp /host/build/bin/linux-${HOST_ARCH}/mkfs.sysv/mkfs.sysv /usr/local/bin/mkfs.sysv && \
    cp /host/build/bin/linux-${HOST_ARCH}/reiserfsprogs/mkfs.reiserfs /usr/local/bin/mkfs.reiserfs

# Runtime libraries for bcachefs
RUN apk add --no-cache libaio keyutils-libs lz4-libs zstd-libs userspace-rcu libsodium eudev-libs

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
