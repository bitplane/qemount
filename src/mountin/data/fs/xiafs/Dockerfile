FROM builder/disk/qemu
ARG MOUNTIN_BUILD_ARCH
RUN cp /host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-musl/mkfs.xiafs /usr/bin/mkfs.xiafs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
