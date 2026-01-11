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
    cpio \
    xz \
    gzip \
    bzip2 \
    python3 \
    py3-pip

# Amiga filesystem tools
RUN pip3 install --no-cache-dir --break-system-packages amitools

# cramfs tools (not in Alpine repos)
RUN apk add --no-cache --virtual .cramfs-deps git make gcc musl-dev zlib-dev zlib-static \
    && git clone --depth 1 https://github.com/npitre/cramfs-tools.git /tmp/cramfs-tools \
    && cd /tmp/cramfs-tools && make && cp mkcramfs /usr/local/bin/ \
    && cd / && rm -rf /tmp/cramfs-tools && apk del .cramfs-deps

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
