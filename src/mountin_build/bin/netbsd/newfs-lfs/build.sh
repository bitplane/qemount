#!/bin/sh
set -eu

source_dir=$MOUNTIN_CACHE_DIR/source
nbarch=$(cat /tmp/nbarch)

if [ ! -f "$source_dir/.extracted" ]; then
    rm -rf "$source_dir"
    mkdir -p "$source_dir"
    tar -xzf /host/build/sources/netbsd-10.0-src.tgz -C "$source_dir"
    tar -xzf /host/build/sources/netbsd-10.0-syssrc.tgz -C "$source_dir"
    touch "$source_dir/.extracted"
fi

build_dir=$source_dir/usr/src/sbin/newfs_lfs
/usr/tools/bin/nbmake-"$nbarch" -C "$build_dir" \
    NETBSDSRCDIR="$source_dir/usr/src" MKMAN=no LDSTATIC=-static obj
/usr/tools/bin/nbmake-"$nbarch" -C "$build_dir" \
    NETBSDSRCDIR="$source_dir/usr/src" MKMAN=no LDSTATIC=-static dependall

output=/host/build/bin/${OUTPUT_ARCH}-netbsd/newfs_lfs
mkdir -p "$(dirname "$output")"
cp "$build_dir/newfs_lfs" "$output"
