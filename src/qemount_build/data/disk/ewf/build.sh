#!/bin/sh
set -e

OUTPUT="/host/build/$1"
INPUT="/host/build/data/pt/hybrid.gpt"

mkdir -p "$(dirname "$OUTPUT")"

# Strip .E01 extension - ewfacquire adds it automatically
TARGET="${OUTPUT%.E01}"

ewfacquire -u -q -f encase6 -c deflate:fast -d sha1 -S 0 -t "$TARGET" "$INPUT"
