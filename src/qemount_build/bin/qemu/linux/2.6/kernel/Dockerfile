ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
ADD build.sh /build.sh
ADD kernel.config /kernel.config
ADD filesystems.config /filesystems.config
RUN chmod +x /build.sh
ENTRYPOINT ["/build.sh"]
