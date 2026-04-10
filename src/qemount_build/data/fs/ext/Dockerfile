FROM builder/disk/qemu
ARG HOST_ARCH
RUN cp /host/build/bin/${HOST_ARCH}-linux-musl/mkfs.ext /usr/bin/mkfs.ext
COPY --chmod=755 buildfs.sh /build/buildfs.sh
