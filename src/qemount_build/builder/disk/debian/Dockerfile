FROM debian:bookworm-slim

# Debian disk tools for creating filesystem images without mount access
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        tar \
        jq \
        genromfs \
        hfsutils \
        makefs \
        parted \
        qemu-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
