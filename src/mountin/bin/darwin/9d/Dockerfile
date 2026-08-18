ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

COPY --chmod=755 build.sh /build.sh
COPY stream64.c /stream64.c
ENTRYPOINT ["/build.sh"]
