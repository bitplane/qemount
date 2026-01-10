FROM docker.io/library/alpine:latest

# Linux disk tools for creating filesystem images without mount access
RUN apk add --no-cache \
    bash \
    tar \
    e2fsprogs \
    e2fsprogs-extra \
    dosfstools \
    mtools \
    squashfs-tools \
    erofs-utils \
    cpio \
    xz \
    gzip \
    bzip2

WORKDIR /build
