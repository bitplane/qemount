FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bzip2 \
    ksh \
    libelf-dev \
    libtirpc-dev \
    m4 \
    perl \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
