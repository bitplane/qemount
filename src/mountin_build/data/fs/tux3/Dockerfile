FROM builder/disk/qemu
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-gnu/mkfs.tux3 /usr/bin/mkfs.tux3
COPY --chmod=755 buildfs.sh /build/buildfs.sh
