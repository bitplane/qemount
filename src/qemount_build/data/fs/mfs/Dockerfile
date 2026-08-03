FROM builder/disk/qemu
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-musl/mkfs.mfs /usr/bin/mkfs.mfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
