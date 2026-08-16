#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template/basic
zoo a /tmp/output.zoo hello.txt script.sh

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.zoo "/host/build/$OUTPUT_PATH"
