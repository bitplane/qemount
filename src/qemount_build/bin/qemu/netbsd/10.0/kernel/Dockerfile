ARG BUILDER
FROM ${BUILDER}

WORKDIR /usr/src
COPY --chmod=755 build.sh /build.sh
COPY QEMOUNT /QEMOUNT
ENTRYPOINT ["/build.sh"]
