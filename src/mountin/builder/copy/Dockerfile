FROM busybox:1.37.0-musl

COPY --chmod=755 copy.sh /usr/local/bin/mountin-copy

ENTRYPOINT ["/usr/local/bin/mountin-copy"]
