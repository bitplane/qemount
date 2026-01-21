ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY boot.cfg /boot.cfg
COPY disklabel.proto /disklabel.proto
ENTRYPOINT ["/build.sh"]
