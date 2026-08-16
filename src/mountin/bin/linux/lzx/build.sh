#!/bin/sh
set -eu

VERSION=0.1.1
SOURCE_DIR=/work/amiga-lzx-cli-$VERSION
TARGET_TRIPLE=${OUTPUT_ARCH}-unknown-linux-musl
TARGET_DIR=${CARGO_TARGET_DIR:-target}
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-linux-musl

rm -rf "$SOURCE_DIR"
tar -xzf "/host/build/sources/amiga-lzx-cli-$VERSION.tar.gz" -C /work
cd "$SOURCE_DIR"

cargo zigbuild --release --locked --target "$TARGET_TRIPLE"

mkdir -p "$OUTPUT_DIR"
cp "$TARGET_DIR/$TARGET_TRIPLE/release/lzx" "$OUTPUT_DIR/lzx"
