ARG BUILDER
FROM ${BUILDER}

WORKDIR /usr/src
ADD build.sh /build.sh
ADD QEMOUNT /QEMOUNT
RUN chmod +x /build.sh
ENTRYPOINT ["/build.sh"]
