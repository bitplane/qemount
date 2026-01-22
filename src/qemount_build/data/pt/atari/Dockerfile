FROM alpine:latest
RUN apk add --no-cache coreutils
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
