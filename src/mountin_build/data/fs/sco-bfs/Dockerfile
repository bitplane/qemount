FROM builder/disk/alpine
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-musl/mkfs.bfs /usr/bin/mkfs.bfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
