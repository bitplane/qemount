FROM builder/disk/qemu
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-musl/mkfs.xiafs /usr/bin/mkfs.xiafs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
