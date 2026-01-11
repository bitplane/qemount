FROM docker.io/library/alpine:latest
RUN apk add --no-cache e2fsprogs e2fsprogs-extra tar jq
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
