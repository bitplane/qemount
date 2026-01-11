FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc libc6-dev qemu-system-x86 e2fsprogs bash \
    && rm -rf /var/lib/apt/lists/*
COPY mkfs.sysv.c /build/
RUN gcc -o /usr/local/bin/mkfs.sysv /build/mkfs.sysv.c
COPY build.sh /build/
RUN chmod +x /build/build.sh
ENTRYPOINT ["/build/build.sh"]
