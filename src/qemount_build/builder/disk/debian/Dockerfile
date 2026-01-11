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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
