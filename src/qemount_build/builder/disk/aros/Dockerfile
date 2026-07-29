FROM builder/disk/alpine

RUN apk del cdrkit \
    && apk add --no-cache \
        qemu-system-x86_64 \
        xorriso
