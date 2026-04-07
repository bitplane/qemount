FROM builder/compiler/linux/6

WORKDIR /work
COPY mkfs.ext.c /work/
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
