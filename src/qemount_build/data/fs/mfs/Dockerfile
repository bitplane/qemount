FROM builder/disk/qemu
ARG HOST_ARCH
RUN cp /host/build/bin/${HOST_ARCH}-linux-musl/mkfs.mfs /usr/bin/mkfs.mfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
