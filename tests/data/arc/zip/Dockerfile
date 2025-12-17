FROM docker.io/library/alpine:latest
RUN apk add --no-cache zip tar
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
