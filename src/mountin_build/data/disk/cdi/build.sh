#!/bin/sh
set -e

OUTPUT="/host/build/$1"
AUDIO="/host/build/data/media/talking.cdda"
DATA="/host/build/data/fs/basic.iso9660"

mkdir -p "$(dirname "$OUTPUT")"
python3 /build/mkcdi.py "$OUTPUT" "$AUDIO:audio" "$DATA:mode1"
