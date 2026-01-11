ARG HOST_ARCH
FROM builder/compiler/netbsd/10.0:${HOST_ARCH} AS netbsd

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends tar jq zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Copy NetBSD makefs (supports v7fs, ffs, cd9660, msdos)
COPY --from=netbsd /usr/obj/tools/makefs/makefs /usr/local/bin/makefs

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
