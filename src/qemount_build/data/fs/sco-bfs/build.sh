#!/bin/sh
set -e

OUTPUT_PATH="$1"
BASE_NAME=$(basename "$OUTPUT_PATH" .sco-bfs)
TAR_PATH="/host/build/tests/data/templates/${BASE_NAME}.tar"

mkdir -p /tmp/template
tar -xf "$TAR_PATH" -C /tmp/template

# Create a 10MB file for SCO BFS
dd if=/dev/zero of=/tmp/output.sco-bfs bs=1M count=10

# Format as SCO BFS (Boot File System)
mkfs.bfs -v /tmp/output.sco-bfs

# Note: SCO BFS doesn't support standard mount on Linux
# Just create the filesystem image
# The files from template will need to be added by the guest that supports it

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.sco-bfs "/host/build/$OUTPUT_PATH"
