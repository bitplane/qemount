FROM builder/compiler/linux/6

WORKDIR /work
COPY mkfs.sysv.c /work/
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
