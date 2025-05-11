FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ntfs-3g \
    tar \
    && rm -rf /var/lib/apt/lists/*
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]