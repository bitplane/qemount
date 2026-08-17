#!/bin/sh
set -eu

source=/host/build/guest/${OUTPUT_PLATFORM}/6.4.2/dragonfly.iso
output=/host/build/bin/qemu/${OUTPUT_PLATFORM}/6.4.2/system/dragonfly.iso
mkdir -p "${output%/*}"
cp "$source" "$output"
