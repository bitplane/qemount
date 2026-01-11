#!/bin/sh
# $1 = input directory
# $2 = output file
set -e

# Create empty image
dd if=/dev/zero of="$2" bs=1M count=10

# Initialize as BeOS BFS
bfs_shell --initialize "$2" TestVol

# Copy files
cd "$1"
find . -type f | while read file; do
    dir=$(dirname "$file")
    if [ "$dir" != "." ]; then
        echo "mkdir -p \"/myfs/$dir\"" | bfs_shell "$2"
    fi
    echo "cp :\"$(pwd)/$file\" \"/myfs/$file\"" | bfs_shell "$2"
done
