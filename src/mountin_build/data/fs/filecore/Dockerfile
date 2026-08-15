FROM builder/disk/debian

RUN apt-get update && \
    apt-get install -y --no-install-recommends fp-compiler fp-units-fcl && \
    rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    mkdir -p /work/disc-image-manager; \
    tar -xzf /host/build/sources/disc-image-manager-1.50.1.tar.gz \
        -C /work/disc-image-manager --strip-components=1; \
    cd '/work/disc-image-manager/LazarusSource 1.50'; \
    fpc -O3 -dNO_GUI DiscImageManagerCLI.lpr; \
    cp DiscImageManagerCLI /usr/local/bin/disc-image-manager; \
    rm -rf /work/disc-image-manager

COPY --chmod=755 buildfs.sh /build/buildfs.sh
