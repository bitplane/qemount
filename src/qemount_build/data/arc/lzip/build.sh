#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

lzip -c < "$INPUT" > /tmp/output.tar.lz

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.lz "/host/build/$OUTPUT_PATH"
