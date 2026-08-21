#!/bin/sh
set -eu

BASE_IMAGE=/host/build/guest/${MOUNTIN_TARGET_ARCH}-haiku/r1-beta6-hrev59919+1/haiku.image
NINED=/host/build/bin/${MOUNTIN_TARGET_ARCH}-haiku/9d
INIT=/host/build/bin/${MOUNTIN_TARGET_ARCH}-haiku/mountin-init
OUTPUT_DIR=/host/build/bin/qemu/${MOUNTIN_TARGET_ARCH}-haiku/r1-beta6-hrev59919+1
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
WORK_IMAGE=$OUTPUT_DIR/.haiku.image.tmp
BFS_IMAGE=$WORK_IMAGE

mkdir -p "$OUTPUT_DIR"
rm -f "$WORK_IMAGE"
cp "$BASE_IMAGE" "$WORK_IMAGE"

case "$MOUNTIN_TARGET_ARCH" in
	x86_64) ;;
	aarch64)
		BFS_IMAGE=/work/haiku.bfs
		set -- $(partx --raw --output START,SECTORS,TYPE "$WORK_IMAGE" \
			| awk '$3 == "0xeb" { print $1, $2 }')
		test "$#" -eq 2
		partition_start=$1
		partition_sectors=$2
		dd if="$WORK_IMAGE" of="$BFS_IMAGE" bs=512 \
			skip="$partition_start" count="$partition_sectors"
		;;
	*)
		echo "Unsupported Haiku architecture: $MOUNTIN_TARGET_ARCH" >&2
		exit 1
		;;
esac

printf '%s\n' \
	'mkdir -p "/myfs/system/non-packaged/bin"' \
	'mkdir -p "/myfs/system/non-packaged/servers"' \
	"cp -f :\"$NINED\" \"/myfs/system/non-packaged/bin/9d\"" \
	"cp -f :\"$INIT\" \"/myfs/system/non-packaged/servers/launch_daemon\"" \
	| bfs_shell "$BFS_IMAGE"

rm -f /work/9d.verify /work/init.verify
printf '%s\n' \
	'cp "/myfs/system/non-packaged/bin/9d" :"/work/9d.verify"' \
	'cp "/myfs/system/non-packaged/servers/launch_daemon" :"/work/init.verify"' \
	| bfs_shell "$BFS_IMAGE"
cmp "$NINED" /work/9d.verify
cmp "$INIT" /work/init.verify
test -x /work/9d.verify
test -x /work/init.verify

if [ "$BFS_IMAGE" != "$WORK_IMAGE" ]; then
	dd if="$BFS_IMAGE" of="$WORK_IMAGE" bs=512 \
		seek="$partition_start" conv=notrunc
	rm -f "$BFS_IMAGE"
fi

mv "$WORK_IMAGE" "$OUTPUT_IMAGE"
