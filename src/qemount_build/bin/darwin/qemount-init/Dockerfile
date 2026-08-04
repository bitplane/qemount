ARG BUILDER
FROM ${BUILDER}

COPY --chmod=755 build.sh /build.sh
COPY qemount-init.c /qemount-init.c
ENTRYPOINT ["/build.sh"]
