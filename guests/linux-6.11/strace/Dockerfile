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
    --disable-mpers 

RUN make -j$(nproc)

RUN mkdir -p /outputs/guests/linux-6.11/rootfs/${ARCH}/bin && \
    cp -v src/strace /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/ && \
    strip /outputs/guests/linux-6.11/rootfs/${ARCH}/bin/strace || true
