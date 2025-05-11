FROM alpine:latest
RUN apk add --no-cache squashfs-tools tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
