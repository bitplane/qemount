FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends makefs tar && \
    rm -rf /var/lib/apt/lists/*
COPY * /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
