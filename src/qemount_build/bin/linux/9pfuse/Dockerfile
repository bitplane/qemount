ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    meson \
    cmake \
    fuse-dev \
    fuse-static \
    linux-headers

WORKDIR /work
ADD build.sh /build.sh
RUN chmod +x /build.sh
