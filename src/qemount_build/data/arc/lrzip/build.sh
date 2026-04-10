#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

cp "$INPUT" /tmp/basic.tar
lrzip /tmp/basic.tar -o /tmp/output.tar.lrz

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.lrz "/host/build/$OUTPUT_PATH"
