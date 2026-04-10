#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
rar a /tmp/output.rar *

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.rar "/host/build/$OUTPUT_PATH"
