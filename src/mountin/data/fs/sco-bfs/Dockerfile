FROM builder/disk/alpine
ARG MOUNTIN_BUILD_ARCH
RUN cp /host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-musl/mkfs.bfs /usr/bin/mkfs.bfs
COPY --chmod=755 buildfs.sh /build/buildfs.sh
