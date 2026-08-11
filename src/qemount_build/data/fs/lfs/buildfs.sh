#!/bin/sh
set -eu

input=$1
output=$2
work=/work/lfs
helper=$work/helper
helper_image=$work/helper.fs
boot=/host/build/bin/qemu/x86_64-netbsd/10.0/boot/boot.img
formatter=/host/build/bin/x86_64-netbsd/newfs_lfs

rm -rf "$work"
mkdir -p "$helper/TestData"
cp -Rp "$input"/. "$helper/TestData"/
cp "$formatter" "$helper/newfs_lfs"

makefs -t ffs -o version=1 "$helper_image" "$helper"
truncate -s 64M "$output"

python3 /build/run.py "$boot" "$output" "$helper_image"
