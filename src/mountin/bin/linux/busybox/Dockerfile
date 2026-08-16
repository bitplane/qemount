ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY merge_config.py /merge_config.py
COPY busybox.config /busybox.config
ENTRYPOINT ["/build.sh"]
