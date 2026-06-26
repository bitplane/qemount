#!/bin/sh
# $1 = template directory, $2 = output APRIDISK file
set -e

TEMPLATE="$1"
OUTPUT="$2"

# Build a 1.44MB FAT12 floppy: 80 tracks x 2 heads x 18 sectors x 512 bytes.
# This matches APRIDISK's documented maximum geometry (2880 sectors).
FAT=/tmp/floppy.fat12
truncate -s 1474560 "$FAT"
mkfs.fat -F 12 -S 512 "$FAT"

export MTOOLSRC="/tmp/mtoolsrc"
echo "drive c: file=\"$FAT\"" > "$MTOOLSRC"

cd "$TEMPLATE"
find . -type d | while read -r dir; do
    [ "$dir" = "." ] && continue
    mmd "c:/${dir#./}" 2>/dev/null || true
done

find . -type f | while read -r file; do
    mcopy -o "$TEMPLATE/${file#./}" "c:/${file#./}"
done

# Wrap the raw FAT12 image in an APRIDISK container.
python3 /build/mkapridisk.py "$FAT" "$OUTPUT"
