#!/bin/sh
set -eu

output=/host/build/$1
filesystem=/host/build/data/fs/basic.hfs
start=2048
size=$(( $(stat -c %s "$filesystem") / 512 ))

mkdir -p "$(dirname "$output")"
truncate -s $(( (start + size + 2048) * 512 )) "$output"
sfdisk "$output" <<EOF
label: dos
start=$start, size=$size, type=af
EOF
dd if="$filesystem" of="$output" bs=512 seek=$start conv=notrunc status=none
dd if="$output" bs=512 skip=$start count=$size status=none | cmp - "$filesystem"
