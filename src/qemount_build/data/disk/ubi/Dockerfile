FROM alpine:latest
RUN apk add --no-cache mtd-utils-ubi jq
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
