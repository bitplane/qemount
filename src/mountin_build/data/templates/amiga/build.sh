#!/bin/sh
set -eu

work=/tmp/amiga-template
rm -rf "$work"
mkdir -p "$work"
tar -xf /host/build/data/templates/basic.tar -C "$work"

for output in "$@"; do
    output_path="/host/build/$output"
    mkdir -p "$(dirname "$output_path")"
    python3 /build/generate_amiga_script.py "$work/basic" "$output_path"
    echo "Built: $output"
done
