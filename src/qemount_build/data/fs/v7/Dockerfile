ARG ARCH
FROM localhost/qemount-common-compiler-netbsd-10.0-${ARCH} AS netbsd

FROM docker.io/library/debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends tar zlib1g \
    && rm -rf /var/lib/apt/lists/*
COPY --from=netbsd /usr/obj/tools/makefs/makefs /usr/local/bin/makefs
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
