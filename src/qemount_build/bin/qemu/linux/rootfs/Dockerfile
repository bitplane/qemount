ARG BUILDER
FROM ${BUILDER}

RUN apk add --no-cache e2fsprogs

WORKDIR /work
ADD build.sh /build.sh
ADD root /root
RUN chmod +x /build.sh
ENTRYPOINT ["/build.sh"]
