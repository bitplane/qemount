FROM builder/disk/debian

# Build zoo from source
RUN tar -xzf /host/build/sources/zoo-2.1.tar.gz -C /tmp && \
    cd /tmp/zoo-* && \
    make linux && \
    cp zoo /usr/local/bin/ && \
    rm -rf /tmp/zoo-*

COPY --chmod=755 build.sh /build/build.sh
