ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache \
    zlib-dev \
    autoconf \
    automake

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
