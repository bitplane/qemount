FROM docker.io/library/debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils gcc-multilib \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 build.sh /build/build.sh
COPY boot.S /build/boot.S

ENTRYPOINT ["/build/build.sh"]
