FROM builder/disk/alpine
ARG HOST_ARCH
RUN cp /host/build/bin/${HOST_ARCH}-linux-musl/mkfs.bfs /usr/bin/mkfs.bfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
