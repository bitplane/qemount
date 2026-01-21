FROM alpine:latest

# Linux disk tools for creating filesystem images without mount access
RUN apk add --no-cache \
    bash \
    tar \
    jq \
    e2fsprogs \
    e2fsprogs-extra \
    dosfstools \
    mtools \
    squashfs-tools \
    erofs-utils \
    cdrkit \
    mtd-utils-jffs \
    mtd-utils-ubi \
    btrfs-progs \
    util-linux \
    gptfdisk \
    cpio \
    xz \
    gzip \
    bzip2 \
    python3 \
    py3-pip

# Amiga filesystem tools
RUN pip3 install --no-cache-dir --break-system-packages amitools

# cramfs tools (not in Alpine repos, built from mounted source)
RUN apk add --no-cache --virtual .cramfs-deps make gcc musl-dev zlib-dev zlib-static \
    && tar -xzf /host/build/sources/cramfs-tools-2.1.tar.gz -C /tmp \
    && cd /tmp/cramfs-tools-2.1 && make && cp mkcramfs /usr/local/bin/ \
    && cd / && rm -rf /tmp/cramfs-tools-2.1 && apk del .cramfs-deps

WORKDIR /build
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
