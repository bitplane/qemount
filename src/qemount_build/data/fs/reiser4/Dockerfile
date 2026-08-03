FROM builder/disk/qemu
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-gnu/mkfs.reiser4 /usr/bin/mkfs.reiser4 && \
    cp /host/build/bin/${BUILD_ARCH}-linux-gnu/reiser4-busy /usr/bin/reiser4-busy
COPY --chmod=755 buildfs.sh /build/buildfs.sh
