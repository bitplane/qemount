FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    binutils \
    bison \
    bmake \
    build-essential \
    byacc \
    ca-certificates \
    clang \
    flex \
    gawk \
    groff \
    hostname \
    libbsd-dev \
    libfl-dev \
    libncurses-dev \
    libssl-dev \
    libtirpc-dev \
    libz-dev \
    lld \
    patch \
    perl \
    pkg-config \
    python3 \
    tar \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*
