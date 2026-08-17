ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache e2fsprogs e2fsprogs-extra

COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
