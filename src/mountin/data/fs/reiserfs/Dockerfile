FROM builder/disk/qemu
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-gnu/mkfs.reiserfs /usr/bin/mkfs.reiserfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
