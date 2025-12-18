FROM docker.io/library/alpine:latest
RUN apk add --no-cache e2fsprogs e2fsprogs-extra tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
