#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
xar -cf /tmp/output.xar *

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.xar "/host/build/$OUTPUT_PATH"
