FROM builder/disk/qemu
ARG HOST_ARCH
RUN cp /host/build/bin/${HOST_ARCH}-linux-musl/mkfs.sysv /usr/bin/mkfs.sysv
COPY --chmod=755 buildfs.sh /build/buildfs.sh
