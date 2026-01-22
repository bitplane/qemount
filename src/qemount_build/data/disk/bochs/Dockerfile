FROM alpine:latest
RUN apk add --no-cache jq bochs --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
