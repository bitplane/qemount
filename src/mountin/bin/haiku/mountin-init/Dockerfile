ARG BUILDER
FROM ${BUILDER}

ARG TARGET_ARCH
ENV TARGET_ARCH=${TARGET_ARCH}

COPY mountin-init.c /mountin-init.c
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
