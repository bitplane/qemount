#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
find . -type f -exec nulib2 -a /tmp/output.shk {} +

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.shk "/host/build/$OUTPUT_PATH"
