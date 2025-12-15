ARG ARCH
FROM localhost/qemount-common-qemu-builder-${ARCH}

RUN apk add --no-cache ntfs-3g-progs
COPY build.sh /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
