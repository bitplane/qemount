ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    meson \
    cmake \
    fuse-dev \
    fuse-static \
    linux-headers

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
