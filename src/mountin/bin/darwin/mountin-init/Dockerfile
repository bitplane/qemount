ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

COPY --chmod=755 build.sh /build.sh
COPY mountin-init.c /mountin-init.c
ENTRYPOINT ["/build.sh"]
