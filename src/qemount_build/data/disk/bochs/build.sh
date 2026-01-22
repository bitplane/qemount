#!/bin/sh
set -e
OUTPUT="/host/build/$1"
INPUT="/host/build/data/pt/hybrid.gpt"
mkdir -p "$(dirname "$OUTPUT")"
bximage -func=convert -imgmode=growing -q "$INPUT" "$OUTPUT"
