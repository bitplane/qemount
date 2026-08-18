ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY boot.cfg /boot.cfg
COPY disklabel.template /disklabel.template
ENTRYPOINT ["/build.sh"]
