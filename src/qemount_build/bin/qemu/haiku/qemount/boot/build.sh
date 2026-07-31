#!/bin/sh
set -eu

BASE_IMAGE=/host/build/bin/qemu/${ARCH}-haiku/qemount/system/haiku.image
SIMPLE9P=/host/build/bin/${ARCH}-haiku/simple9p
OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-haiku/qemount/boot
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
WORK_IMAGE=$OUTPUT_DIR/.haiku.image.tmp

mkdir -p "$OUTPUT_DIR"
rm -f "$WORK_IMAGE"
cp "$BASE_IMAGE" "$WORK_IMAGE"

printf '%s\n' \
    'mkdir -p "/myfs/system/non-packaged/bin"' \
    'mkdir -p "/myfs/system/non-packaged/data/launch"' \
    'mkdir -p "/myfs/system/non-packaged/data/qemount"' \
    "cp -f :\"$SIMPLE9P\" \"/myfs/system/non-packaged/bin/simple9p\"" \
    'cp -f :"/UserBootscript" "/myfs/system/non-packaged/data/qemount/UserBootscript"' \
    'cp -f :"/qemount.launch" "/myfs/system/non-packaged/data/launch/qemount"' \
    | bfs_shell "$WORK_IMAGE"

rm -f /work/simple9p.verify /work/UserBootscript.verify /work/qemount.launch.verify
printf '%s\n' \
    'cp "/myfs/system/non-packaged/bin/simple9p" :"/work/simple9p.verify"' \
    'cp "/myfs/system/non-packaged/data/qemount/UserBootscript" :"/work/UserBootscript.verify"' \
    'cp "/myfs/system/non-packaged/data/launch/qemount" :"/work/qemount.launch.verify"' \
    | bfs_shell "$WORK_IMAGE"
cmp "$SIMPLE9P" /work/simple9p.verify
cmp /UserBootscript /work/UserBootscript.verify
cmp /qemount.launch /work/qemount.launch.verify
test -x /work/simple9p.verify
test -x /work/UserBootscript.verify

mv "$WORK_IMAGE" "$OUTPUT_IMAGE"
