ARG BUILDER
FROM ${BUILDER}

COPY --chmod=755 build.sh /build.sh
COPY stream64.c /stream64.c
ENTRYPOINT ["/build.sh"]
