#!/bin/sh
set -eu

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"
python3 /build/build.py \
    /host/build/data/fs/basic.ufs-solaris \
    "$OUTPUT"

