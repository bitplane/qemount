FROM builder/disk/alpine
ARG BUILD_ARCH
RUN cp /host/build/bin/${BUILD_ARCH}-linux-musl/mkfs.sysv /usr/bin/mkfs.sysv
COPY --chmod=755 buildfs.sh /build/buildfs.sh
