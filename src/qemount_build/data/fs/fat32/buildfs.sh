#!/bin/sh
# $1 = input directory
# $2 = output file
set -e

truncate -s 35M "$2"
mkfs.fat -F 32 -S 512 "$2"

export MTOOLSRC="/tmp/mtoolsrc"
echo "drive c: file=\"$2\"" > "$MTOOLSRC"

cd "$1"
find . -type d | while read -r dir; do
    [ "$dir" = "." ] && continue
    mmd "c:/${dir#./}" 2>/dev/null || true
done

find . -type f | while read -r file; do
    mcopy -o "$1/${file#./}" "c:/${file#./}"
done
