FROM debian:bookworm-slim
ARG HOST_ARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libc6-dev uuid-dev comerr-dev libacl1-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
