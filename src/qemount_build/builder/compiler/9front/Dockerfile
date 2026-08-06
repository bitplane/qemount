FROM docker.io/debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    dosfstools \
    genisoimage \
    gzip \
    mtools \
    python3 \
    python3-pexpect \
    qemu-system-x86 \
    qemu-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
