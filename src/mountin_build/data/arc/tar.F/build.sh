#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

freeze -c < "$INPUT" > /tmp/output.tar.F

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.tar.F "/host/build/$OUTPUT_PATH"
