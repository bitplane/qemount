ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache e2fsprogs

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY root /root
ENTRYPOINT ["/build.sh"]
