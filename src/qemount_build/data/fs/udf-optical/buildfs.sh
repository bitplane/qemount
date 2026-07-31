#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
set -eu

truncate -s 16M "$2"
mkudffs \
    --blocksize=2048 \
    --label=QEMOUNT_UDF_OPTICAL \
    --media-type=hd \
    --noefe \
    --udfrev=1.02 \
    "$2"
