#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
jlha a /tmp/output.lzh *

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.lzh "/host/build/$OUTPUT_PATH"
