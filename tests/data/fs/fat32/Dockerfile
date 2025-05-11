FROM alpine:latest
RUN apk add --no-cache dosfstools mtools tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
