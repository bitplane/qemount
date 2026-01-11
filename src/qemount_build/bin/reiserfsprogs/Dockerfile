FROM debian:bookworm-slim
ARG HOST_ARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libacl1-dev uuid-dev libext2fs-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY build.sh /build.sh
RUN chmod +x /build.sh
ENTRYPOINT ["/build.sh"]
