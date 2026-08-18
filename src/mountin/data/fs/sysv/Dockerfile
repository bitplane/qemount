FROM builder/disk/alpine
ARG MOUNTIN_BUILD_ARCH
RUN cp /host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-musl/mkfs.sysv /usr/bin/mkfs.sysv
COPY --chmod=755 buildfs.sh /build/buildfs.sh
