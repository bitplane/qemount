ARG ARCH
FROM localhost/qemount-common-compiler-${ARCH}
ARG ARCH

RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    linux-headers

WORKDIR /build

RUN git clone --depth 1 https://github.com/bitplane/simple9p.git && \
    cd simple9p && \
    ./build.sh

RUN mkdir -p /outputs/guests/linux/rootfs/${ARCH}/bin
RUN cp    -v /build/simple9p/build/simple9p /outputs/guests/linux/rootfs/${ARCH}/bin/

