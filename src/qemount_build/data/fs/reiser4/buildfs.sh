#!/bin/sh
# $1 = input directory
# $2 = output file

# Create a 64MB image (reiser4 needs at least ~33MB)
truncate -s 64M "$2"
mkfs.reiser4 -f -y "$2"

# Populate using reiser4-busy (userspace tool, no kernel mount needed)
# Path format: device:/path for reiser4, ^/path for host filesystem

# Create directories first
find "$1" -type d | sort | while read dir; do
    rel=$(echo "$dir" | sed "s|^$1||")
    [ -z "$rel" ] && continue
    reiser4-busy mkdir "$2:$rel"
done

# Copy files
# cp syntax: busy cp SRC DST in_offset out_offset count blk_size
# -1 means start/end/unlimited
find "$1" -type f | sort | while read f; do
    rel=$(echo "$f" | sed "s|^$1||")
    reiser4-busy create "$2:$rel"
    size=$(stat -c %s "$f")
    reiser4-busy cp "^$f" "$2:$rel" 0 0 "$size" 1
done
