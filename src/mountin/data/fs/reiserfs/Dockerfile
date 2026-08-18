FROM builder/disk/qemu
ARG MOUNTIN_BUILD_ARCH
RUN cp /host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-gnu/mkfs.reiserfs /usr/bin/mkfs.reiserfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
