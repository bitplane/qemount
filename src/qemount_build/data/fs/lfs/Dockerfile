FROM builder/disk/netbsd

RUN apt-get update && \
    apt-get install -y --no-install-recommends qemu-system-x86 python3 && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 buildfs.sh run.py /build/
