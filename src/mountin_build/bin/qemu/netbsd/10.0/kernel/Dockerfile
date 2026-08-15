ARG BUILDER
FROM ${BUILDER}

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
COPY MOUNTIN /MOUNTIN
COPY MOUNTIN.evbarm /MOUNTIN.evbarm
ENTRYPOINT ["/build.sh"]
