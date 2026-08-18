ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY root /root
ENTRYPOINT ["/build.sh"]
