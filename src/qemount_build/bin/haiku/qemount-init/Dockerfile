ARG BUILDER
FROM ${BUILDER}

ARG ARCH
ENV ARCH=${ARCH}

COPY qemount-init.c /qemount-init.c
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
