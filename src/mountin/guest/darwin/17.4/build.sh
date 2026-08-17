#!/bin/sh
set -eu

output=/host/build/guest/${OUTPUT_PLATFORM}/17.4/system
mkdir -p "${output%/*}"
temporary=${output}.tmp
rm -rf "$temporary"
mkdir -p "$temporary"
cp -a --no-preserve=ownership /opt/puredarwin/. "$temporary/"
rm -rf "$output"
mv "$temporary" "$output"
