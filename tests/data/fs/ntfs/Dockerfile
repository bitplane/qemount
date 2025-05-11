ARG ARCH
FROM qemount-common-compiler-${ARCH}
ARG ARCH

# For Alpine, we can only create empty NTFS filesystems
RUN apk add --no-cache ntfs-3g-progs tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]