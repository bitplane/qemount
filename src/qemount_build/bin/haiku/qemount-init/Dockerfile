ARG BUILDER
FROM ${BUILDER}

ARG OUTPUT_ARCH
ENV OUTPUT_ARCH=${OUTPUT_ARCH}

COPY qemount-init.c /qemount-init.c
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
