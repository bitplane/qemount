ARG BUILDER
FROM ${BUILDER}

WORKDIR /usr/src
COPY --chmod=755 build.sh /build.sh
COPY QEMOUNT /QEMOUNT
COPY QEMOUNT.evbarm /QEMOUNT.evbarm
ENTRYPOINT ["/build.sh"]
