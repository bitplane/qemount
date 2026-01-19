#!/bin/bash
set -e

OUT=/host/build/lib

# Embed format.bin at compile time
export QEMOUNT_FORMAT_BIN=/host/build/lib/format.bin

# Linux musl (fully static, portable - no .so, musl doesn't support cdylib)
for arch in x86_64 aarch64; do
    cargo zigbuild --release --target ${arch}-unknown-linux-musl
    mkdir -p ${OUT}/linux-${arch}-musl
    cp target/${arch}-unknown-linux-musl/release/libqemount.a ${OUT}/linux-${arch}-musl/
done

# Linux gnu (glibc 2.17 compat)
for arch in x86_64 aarch64; do
    cargo zigbuild --release --target ${arch}-unknown-linux-gnu.2.17
    mkdir -p ${OUT}/linux-${arch}-gnu
    cp target/${arch}-unknown-linux-gnu/release/libqemount.a ${OUT}/linux-${arch}-gnu/
    cp target/${arch}-unknown-linux-gnu/release/libqemount.so ${OUT}/linux-${arch}-gnu/
done

# Windows (x86_64 only - aarch64-pc-windows-gnu not a supported Rust target)
cargo zigbuild --release --target x86_64-pc-windows-gnu
mkdir -p ${OUT}/windows-x86_64
cp target/x86_64-pc-windows-gnu/release/qemount.dll ${OUT}/windows-x86_64/
cp target/x86_64-pc-windows-gnu/release/libqemount.a ${OUT}/windows-x86_64/qemount.lib

# macOS
for arch in x86_64 aarch64; do
    cargo zigbuild --release --target ${arch}-apple-darwin
    mkdir -p ${OUT}/darwin-${arch}
    cp target/${arch}-apple-darwin/release/libqemount.a ${OUT}/darwin-${arch}/
    cp target/${arch}-apple-darwin/release/libqemount.dylib ${OUT}/darwin-${arch}/
done

# WASM
cargo zigbuild --release --target wasm32-wasip1
mkdir -p ${OUT}/wasm
cp target/wasm32-wasip1/release/qemount.wasm ${OUT}/wasm/

# C header
mkdir -p ${OUT}/include
cp /build/include/qemount.h ${OUT}/include/

echo "Build complete"
