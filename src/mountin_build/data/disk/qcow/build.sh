#!/bin/sh
set -e
OUTPUT="/host/build/$1"
INPUT="/host/build/data/pt/hybrid.gpt"
mkdir -p "$(dirname "$OUTPUT")"
qemu-img convert -f raw -O qcow "$INPUT" "$OUTPUT"
