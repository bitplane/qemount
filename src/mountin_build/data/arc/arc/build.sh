#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/work
tar -xf "$INPUT" -C /tmp/work

# arc works in current directory, add just the flat files
cd /tmp/work/basic
arc a /tmp/output.arc hello.txt script.sh

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.arc "/host/build/$OUTPUT_PATH"
