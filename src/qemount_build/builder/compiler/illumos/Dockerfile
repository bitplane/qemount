FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

ARG BUILD_ARCH
ARG JOBS

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

COPY --chmod=755 build.sh /build/build.sh

RUN /build/build.sh

WORKDIR /source/usr/src
