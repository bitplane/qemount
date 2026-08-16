FROM alpine:3.22

RUN apk add --no-cache jq

COPY --chmod=755 copy.sh /usr/local/bin/mountin-copy

ENTRYPOINT ["/usr/local/bin/mountin-copy"]
