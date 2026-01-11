FROM alpine:latest
RUN apk add --no-cache mtd-utils-ubi jq
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
