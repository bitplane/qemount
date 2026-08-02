ARG BUILDER
FROM ${BUILDER}

COPY --chmod=755 build.sh /build.sh
COPY provision.sh /provision.sh
ENTRYPOINT ["/build.sh"]
