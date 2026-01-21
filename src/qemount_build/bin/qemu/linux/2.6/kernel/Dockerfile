ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY kernel.config /kernel.config
COPY filesystems.config /filesystems.config
ENTRYPOINT ["/build.sh"]
