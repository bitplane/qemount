FROM docker.io/library/debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ghc \
        libcurl4-openssl-dev \
        libghc-old-time-dev \
        libncurses-dev \
        patch \
    && rm -rf /var/lib/apt/lists/*
