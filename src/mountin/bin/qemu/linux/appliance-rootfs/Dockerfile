ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache e2fsprogs

COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
