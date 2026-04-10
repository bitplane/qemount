FROM builder/disk/debian
RUN apt-get update && \
    apt-get install -y --no-install-recommends nulib2 && \
    rm -rf /var/lib/apt/lists/*
COPY --chmod=755 build.sh /build/build.sh
