ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY root /root
ENTRYPOINT ["/build.sh"]
