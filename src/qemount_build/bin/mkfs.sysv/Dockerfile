ARG HOST_ARCH
FROM localhost/builder-compiler-linux-6-${HOST_ARCH}

WORKDIR /work
COPY mkfs.sysv.c /work/
COPY build.sh /build.sh
RUN chmod +x /build.sh
ENTRYPOINT ["/build.sh"]
