ARG HOST_ARCH
FROM builder/compiler/linux/6:${HOST_ARCH}

WORKDIR /work
COPY mkfs.sysv.c /work/
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
