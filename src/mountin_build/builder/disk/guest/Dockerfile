FROM builder/disk/alpine

RUN apk del cdrkit \
    && apk add --no-cache \
        qemu-system-x86_64 \
        xorriso

COPY --chmod=755 run-until-marker.sh /usr/local/bin/run-until-marker
