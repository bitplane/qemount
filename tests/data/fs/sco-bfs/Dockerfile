FROM alpine:latest
RUN apk add --no-cache util-linux tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
