#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
zpaq a /tmp/output.zpaq *

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.zpaq "/host/build/$OUTPUT_PATH"
