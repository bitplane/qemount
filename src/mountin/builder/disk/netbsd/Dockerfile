ARG MOUNTIN_BUILDER
FROM ${MOUNTIN_BUILDER} AS netbsd

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends tar jq zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Copy NetBSD tools (makefs supports v7fs, ffs, cd9660, msdos)
COPY --from=netbsd /usr/tools/bin/nbmakefs /usr/local/bin/makefs
COPY --from=netbsd /usr/tools/bin/nbdisklabel /usr/local/bin/nbdisklabel

WORKDIR /build
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
