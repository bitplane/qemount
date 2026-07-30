ARG ARCH
FROM builder/compiler/haiku
ARG ARCH

# Build bfs_shell tool
WORKDIR /src/haiku/generated
RUN jam -q '<build>bfs_shell'

# Install to standard location
RUN cp /src/haiku/generated/objects/linux/${ARCH}/release/tools/bfs_shell/bfs_shell /usr/local/bin/bfs_shell

WORKDIR /build
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
