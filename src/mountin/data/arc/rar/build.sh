#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
find . -type l -delete
/host/build/bin/${MOUNTIN_BUILD_ARCH}-linux-musl/rars \
    a --format rar50 /tmp/output.rar *

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.rar "/host/build/$OUTPUT_PATH"
