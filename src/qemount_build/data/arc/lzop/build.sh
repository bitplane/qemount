#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

lzop -c < "$INPUT" > /tmp/output.tar.lzo

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.lzo "/host/build/$OUTPUT_PATH"
