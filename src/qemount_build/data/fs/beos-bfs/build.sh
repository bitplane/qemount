#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .beos-bfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Create a 10MB file for the BeOS BFS image
dd if=/dev/zero of=/tmp/output.beos-bfs bs=1M count=10

# Initialize as BeOS BFS and populate using bfs_shell
/src/haiku/generated/objects/linux/${ARCH}/release/tools/bfs_shell/bfs_shell --initialize /tmp/output.beos-bfs TestVol

# Copy files using a script that handles wildcards in bash, not bfs_shell
BFS_SHELL=/src/haiku/generated/objects/linux/${ARCH}/release/tools/bfs_shell/bfs_shell
cd /tmp/template
find . -type f | while read file; do
    dir=$(dirname "$file")
    if [ "$dir" != "." ]; then
        echo "mkdir -p \"/myfs/$dir\"" | $BFS_SHELL /tmp/output.beos-bfs
    fi
    echo "cp :\"$(pwd)/$file\" \"/myfs/$file\"" | $BFS_SHELL /tmp/output.beos-bfs
done

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.beos-bfs "/host/build/$OUTPUT_PATH"
