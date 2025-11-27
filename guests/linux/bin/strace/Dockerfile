ARG ARCH
FROM localhost/qemount-common-compiler-${ARCH}
ARG ARCH

RUN apk add --no-cache linux-headers

WORKDIR /build

# Download strace release
RUN wget https://github.com/strace/strace/releases/download/v6.7/strace-6.7.tar.xz && \
    tar -xf strace-6.7.tar.xz

WORKDIR /build/strace-6.7

# Configure with static linking using our cross compiler
RUN ./configure \
    --enable-static \
    --disable-shared \
    --disable-mpers \
    --enable-bundled=yes 

RUN make -j$(nproc)

RUN mkdir -p /outputs/guests/linux/rootfs/${ARCH}/bin && \
    cp -v src/strace /outputs/guests/linux/rootfs/${ARCH}/bin/ && \
    strip /outputs/guests/linux/rootfs/${ARCH}/bin/strace || true
