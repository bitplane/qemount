ARG TARGET_ARCH
FROM builder/compiler/haiku/r1-beta6-hrev59919-1
ARG TARGET_ARCH

# Build bfs_shell tool
WORKDIR /src/haiku/generated
RUN jam -q '<build>bfs_shell'

# Install to standard location
RUN cp /src/haiku/generated/objects/linux/${TARGET_ARCH}/release/tools/bfs_shell/bfs_shell /usr/local/bin/bfs_shell

WORKDIR /build
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
