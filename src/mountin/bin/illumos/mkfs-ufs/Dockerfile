ARG BUILDER
FROM ${BUILDER}

COPY --chmod=0755 build.sh /build/build.sh
COPY mkfs-stubs.c /build/mkfs-stubs.c

ENTRYPOINT ["/build/build.sh"]
