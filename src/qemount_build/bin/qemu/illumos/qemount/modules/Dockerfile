ARG BUILDER
FROM ${BUILDER}

COPY --chmod=755 build.sh /build/build.sh
COPY modules.list /build/modules.list
COPY configs.list /build/configs.list
ENTRYPOINT ["/build/build.sh"]
