ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

RUN apk add --no-cache \
    autoconf \
    automake

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
