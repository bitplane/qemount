#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
mkmpq "/host/build/$OUTPUT_PATH" /tmp/template/basic/
