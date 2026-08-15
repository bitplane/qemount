#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
powerpack "$INPUT" "/host/build/$OUTPUT_PATH" -c -e=3
