FROM builder/disk/debian
RUN apt-get update && \
    apt-get install -y --no-install-recommends jlha-utils && \
    rm -rf /var/lib/apt/lists/*
COPY --chmod=755 build.sh /build/build.sh
