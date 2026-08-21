FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        acpica-tools \
        build-essential \
        gcc-aarch64-linux-gnu \
        nasm \
        python3 \
        uuid-dev \
    && rm -rf /var/lib/apt/lists/*

COPY edk2-build.config /edk2-build.config
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
