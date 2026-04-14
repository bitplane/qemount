#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template/basic
/usr/local/bin/lzx c output.lzx hello.txt script.sh

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp output.lzx "/host/build/$OUTPUT_PATH"
