FROM docker.io/library/debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bzip2 \
    ed \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
