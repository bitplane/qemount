FROM alpine:3.23

RUN apk add --no-cache tar xz

COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
