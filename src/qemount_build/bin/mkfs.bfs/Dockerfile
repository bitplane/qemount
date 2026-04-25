FROM builder/compiler/linux/6

WORKDIR /work
COPY mkfs.bfs.c /work/
COPY --chmod=755 build.sh /build.sh
ENTRYPOINT ["/build.sh"]
