#!/bin/sh
# $1 = input directory
# $2 = output file
set -e

truncate -s 8M "$2"
hformat -l "basic" "$2"
hmount "$2"

# Create directories (HFS uses : as path separator)
cd "$1"
find . -type d | sort | while read -r dir; do
    [ "$dir" = "." ] && continue
    dir="${dir#./}"
    hfs_dir=$(echo "$dir" | tr '/' ':')
    hmkdir ":$hfs_dir" 2>/dev/null || true
done

# Copy files (HFS doesn't support symlinks, skip them)
find . -type f | while read -r file; do
    file="${file#./}"
    dir=$(dirname "$file")
    base=$(basename "$file")
    if [ "$dir" = "." ]; then
        hcopy "$1/$file" ":$base"
    else
        hfs_dir=$(echo "$dir" | tr '/' ':')
        hcopy "$1/$file" ":$hfs_dir:$base"
    fi
done

humount
