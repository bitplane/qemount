FROM builder/disk/qemu
ARG HOST_ARCH
RUN cp /host/build/bin/${HOST_ARCH}-linux-musl/mkfs.tux3 /usr/bin/mkfs.tux3
COPY --chmod=755 buildfs.sh /build/buildfs.sh
