#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

# ar only handles flat files, so add top-level files
cd /tmp/template
find . -type f | xargs ar cr /tmp/output.ar

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.ar "/host/build/$OUTPUT_PATH"
