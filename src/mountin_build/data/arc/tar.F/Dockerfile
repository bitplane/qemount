FROM builder/disk/debian

# Build freeze from source
RUN tar -xzf /host/build/sources/freeze-2.5.0.tar.gz -C /tmp && \
    cd /tmp/freeze-* && \
    ./configure && \
    make && \
    cp freeze /usr/local/bin/ && \
    rm -rf /tmp/freeze-*

COPY --chmod=755 build.sh /build/build.sh
