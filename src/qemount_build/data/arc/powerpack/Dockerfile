FROM builder/disk/debian
RUN apt-get update && \
    apt-get install -y --no-install-recommends g++ && \
    rm -rf /var/lib/apt/lists/*

# Build PowerPacker from decompiled source
RUN tar -xzf /host/build/sources/powerpacker.tar.gz -C /tmp && \
    cd /tmp/powerpacker_src-* && \
    g++ -O2 -o /usr/local/bin/powerpack main.cpp && \
    rm -rf /tmp/powerpacker_src-*

COPY --chmod=755 build.sh /build/build.sh
