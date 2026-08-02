#!/bin/sh
set -eu

SOURCE=/host/build/sources/qemu-10.2.0.tar.xz
OUTPUT_DIR=/host/build/bin/qemu-system/firmware
SOURCE_DIR=qemu-10.2.0/pc-bios

mkdir -p "$OUTPUT_DIR"
for firmware in "$@"; do
    filename=${firmware##*/}
    tar -xOf "$SOURCE" "$SOURCE_DIR/$filename" > "$OUTPUT_DIR/$filename.tmp"
    mv "$OUTPUT_DIR/$filename.tmp" "$OUTPUT_DIR/$filename"
done
