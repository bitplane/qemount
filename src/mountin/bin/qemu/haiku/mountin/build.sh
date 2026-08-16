#!/bin/sh
set -eu

BASE_IMAGE=/host/build/bin/qemu/${OUTPUT_ARCH}-haiku/r1-beta6-hrev59919+1/base/haiku.image
NINED=/host/build/bin/${OUTPUT_ARCH}-haiku/9d
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-haiku/r1-beta6-hrev59919+1
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
WORK_IMAGE=$OUTPUT_DIR/.haiku.image.tmp

mkdir -p "$OUTPUT_DIR"
rm -f "$WORK_IMAGE"
cp "$BASE_IMAGE" "$WORK_IMAGE"

printf '%s\n' \
	'mkdir -p "/myfs/system/non-packaged/bin"' \
	"cp -f :\"$NINED\" \"/myfs/system/non-packaged/bin/9d\"" \
	| bfs_shell "$WORK_IMAGE"

rm -f /work/9d.verify
printf '%s\n' \
	'cp "/myfs/system/non-packaged/bin/9d" :"/work/9d.verify"' \
	| bfs_shell "$WORK_IMAGE"
cmp "$NINED" /work/9d.verify
test -x /work/9d.verify

mv "$WORK_IMAGE" "$OUTPUT_IMAGE"
