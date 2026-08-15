#!/bin/sh
set -eu

BASE_IMAGE=/host/build/bin/qemu/${OUTPUT_ARCH}-haiku/r1-beta6-hrev59919+1/base/haiku.image
SIMPLE9P=/host/build/bin/${OUTPUT_ARCH}-haiku/simple9p
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-haiku/r1-beta6-hrev59919+1
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
WORK_IMAGE=$OUTPUT_DIR/.haiku.image.tmp

mkdir -p "$OUTPUT_DIR"
rm -f "$WORK_IMAGE"
cp "$BASE_IMAGE" "$WORK_IMAGE"

printf '%s\n' \
	'mkdir -p "/myfs/system/non-packaged/bin"' \
	"cp -f :\"$SIMPLE9P\" \"/myfs/system/non-packaged/bin/simple9p\"" \
	| bfs_shell "$WORK_IMAGE"

rm -f /work/simple9p.verify
printf '%s\n' \
	'cp "/myfs/system/non-packaged/bin/simple9p" :"/work/simple9p.verify"' \
	| bfs_shell "$WORK_IMAGE"
cmp "$SIMPLE9P" /work/simple9p.verify
test -x /work/simple9p.verify

mv "$WORK_IMAGE" "$OUTPUT_IMAGE"
