#!/bin/sh
set -eu

for target in "$@"; do
    relative=${target#bin/qemu/}
    source=/host/build/guest/$relative
    output=/host/build/$target
    mkdir -p "${output%/*}"
    cp "$source" "$output"
done
