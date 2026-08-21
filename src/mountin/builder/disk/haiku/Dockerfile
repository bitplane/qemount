ARG MOUNTIN_TARGET_ARCH
FROM builder/compiler/haiku/r1-beta6-hrev59919-1
ARG MOUNTIN_TARGET_ARCH

# Build bfs_shell tool
WORKDIR /src/haiku/generated
RUN jam -q '<build>bfs_shell'

# Install to standard location
RUN set -eu; \
    BFS_SHELL=$(find objects/linux -type f \
        -path '*/release/tools/bfs_shell/bfs_shell' -print -quit); \
    test -n "$BFS_SHELL"; \
    cp "$BFS_SHELL" /usr/local/bin/bfs_shell

WORKDIR /build
COPY --chmod=755 build.sh /build/build.sh
ENTRYPOINT ["/build/build.sh"]
