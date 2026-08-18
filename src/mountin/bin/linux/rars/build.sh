#!/bin/sh
set -eu

VERSION=0.4.7
SOURCE_DIR=/work/rars-$VERSION
TARGET_TRIPLE=${TARGET_ARCH}-unknown-linux-musl
TARGET_DIR=${CARGO_TARGET_DIR:-target}
OUTPUT_DIR=/host/build/bin/${TARGET_ARCH}-linux-musl

rm -rf "$SOURCE_DIR"
tar -xzf "/host/build/sources/rars-$VERSION.tar.gz" -C /work
cd "$SOURCE_DIR"

cargo zigbuild --release --locked --package rars-cli \
    --target "$TARGET_TRIPLE"

mkdir -p "$OUTPUT_DIR"
cp "$TARGET_DIR/$TARGET_TRIPLE/release/rars" "$OUTPUT_DIR/rars"
