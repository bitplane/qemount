FROM builder/disk/debian

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates \
        lhasa python3 python3-pip python3-venv python3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/vamos && \
    /opt/vamos/bin/pip install amitools 'machine68k==0.3.0'

# Download LZX 1.21R (freeware keyfile release) from Aminet
RUN curl -sL "https://aminet.net/util/arc/lzx121r1.lha" \
        -o /tmp/lzx.lha && \
    mkdir -p /opt/lzx && \
    cd /opt/lzx && \
    lha x /tmp/lzx.lha && \
    rm /tmp/lzx.lha

COPY --chmod=755 build.sh /build/build.sh
