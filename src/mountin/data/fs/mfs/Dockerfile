FROM builder/disk/qemu
ARG MOUNTIN_BUILD_ARCH
RUN cp /host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-musl/mkfs.mfs /usr/bin/mkfs.mfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
