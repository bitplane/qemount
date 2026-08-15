ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache linux-headers

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
