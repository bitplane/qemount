FROM builder/disk/debian

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates unzip dosbox && \
    rm -rf /var/lib/apt/lists/*

# Mirror: https://archive.org/download/uharc06b/uharc06b.zip
RUN curl -sL "https://www.sac.sk/download/pack/uharc06b.zip" \
        -o /tmp/uharc06b.zip && \
    unzip -j /tmp/uharc06b.zip UHARCD.EXE -d /usr/local/share/uharc && \
    rm /tmp/uharc06b.zip

COPY --chmod=755 build.sh /build/build.sh
