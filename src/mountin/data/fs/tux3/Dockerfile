FROM builder/disk/qemu
ARG MOUNTIN_BUILD_ARCH
RUN cp /host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-gnu/mkfs.tux3 /usr/bin/mkfs.tux3
COPY --chmod=755 buildfs.sh /build/buildfs.sh
