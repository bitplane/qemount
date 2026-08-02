#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"
FREEARC="/host/build/bin/${HOST_ARCH}-linux-gnu/freearc"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cd /tmp/template/basic
"$FREEARC" a "/host/build/$OUTPUT_PATH" hello.txt script.sh
