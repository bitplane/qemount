#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

cd /tmp/template
arj a /tmp/output.arj *

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.arj "/host/build/$OUTPUT_PATH"
