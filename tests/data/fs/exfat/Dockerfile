# testdata/images/exfat/Dockerfile
FROM alpine:latest
RUN apk add --no-cache exfatprogs tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]