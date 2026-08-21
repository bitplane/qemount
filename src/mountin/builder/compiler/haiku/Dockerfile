FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        attr \
        bc \
        bison \
        build-essential \
        bzip2 \
        byacc \
        ca-certificates \
        cmake \
        coreutils \
        device-tree-compiler \
        diffutils \
        file \
        flex \
        gawk \
        genisoimage \
        git \
        jq \
        libcurl4-openssl-dev \
        libssl-dev \
        libtool \
        make \
        mtools \
        nasm \
        ninja-build \
        patch \
        python3 \
        sbsigntool \
        tar \
        texinfo \
        u-boot-tools \
        unzip \
        util-linux \
        wget \
        xorriso \
        xz-utils \
        zip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
