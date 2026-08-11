#!/bin/sh
set -eu

source_dir=$QEMOUNT_CACHE_DIR/source
object_dir=$QEMOUNT_CACHE_DIR/obj
nbarch=$(cat /tmp/nbarch)

if [ ! -f "$source_dir/.extracted" ]; then
    rm -rf "$source_dir"
    mkdir -p "$source_dir"
    tar -xzf /host/build/sources/netbsd-10.0-src.tgz -C "$source_dir"
    tar -xzf /host/build/sources/netbsd-10.0-syssrc.tgz -C "$source_dir"
    touch "$source_dir/.extracted"
fi

mkdir -p "$object_dir"
MAKEOBJDIR="$object_dir" \
    /usr/tools/bin/nbmake-"$nbarch" -C "$source_dir/usr/src/sbin/newfs_lfs" \
    NETBSDSRCDIR="$source_dir/usr/src" MKMAN=no LDSTATIC=-static obj
MAKEOBJDIR="$object_dir" \
    /usr/tools/bin/nbmake-"$nbarch" -C "$source_dir/usr/src/sbin/newfs_lfs" \
    NETBSDSRCDIR="$source_dir/usr/src" MKMAN=no LDSTATIC=-static dependall

output=/host/build/bin/${OUTPUT_ARCH}-netbsd/newfs_lfs
mkdir -p "$(dirname "$output")"
cp "$object_dir/usr/src/sbin/newfs_lfs/newfs_lfs" "$output"
