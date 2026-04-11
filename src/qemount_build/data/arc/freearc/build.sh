#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cd /tmp/template/basic
freearc a "/host/build/$OUTPUT_PATH" hello.txt script.sh
