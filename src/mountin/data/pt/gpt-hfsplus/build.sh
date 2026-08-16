#!/bin/sh
set -eu

output=/host/build/$1
filesystem=/host/build/data/fs/basic.hfsplus
start=2048
size=$(( $(stat -c %s "$filesystem") / 512 ))

mkdir -p "$(dirname "$output")"
truncate -s $(( (start + size + 2048) * 512 )) "$output"
sfdisk "$output" <<EOF
label: gpt
start=$start, size=$size, type=48465300-0000-11AA-AA11-00306543ECAC, name=hfsplus
EOF
dd if="$filesystem" of="$output" bs=512 seek=$start conv=notrunc status=none
dd if="$output" bs=512 skip=$start count=$size status=none | cmp - "$filesystem"
