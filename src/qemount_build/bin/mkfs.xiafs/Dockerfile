FROM builder/compiler/linux/6

WORKDIR /work
COPY mkfs.xiafs.c /work/
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
