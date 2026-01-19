#!/bin/bash
set -e

OUT=/host/build/bin
LIB=/host/build/lib
INCLUDE=/host/build/lib/include

# Use zig via python module
ZIG="python3 -m ziglang"

# Source files - main.c plus Rust allocator shim
SRCS="src/main.c src/rust_alloc.c"

# Linux musl (fully static)
# -lunwind provides _Unwind_* symbols (zig uses its internal vendored libunwind)
for arch in x86_64 aarch64; do
    $ZIG cc -target ${arch}-linux-musl \
        -O2 -static \
        -I${INCLUDE} \
        -L${LIB}/linux-${arch}-musl \
        ${SRCS} -lqemount -lunwind \
        -o detect
    mkdir -p ${OUT}/linux-${arch}-musl
    mv detect ${OUT}/linux-${arch}-musl/
done

# Linux gnu (glibc)
for arch in x86_64 aarch64; do
    $ZIG cc -target ${arch}-linux-gnu \
        -O2 \
        -I${INCLUDE} \
        -L${LIB}/linux-${arch}-gnu \
        ${SRCS} -lqemount -lunwind \
        -o detect
    mkdir -p ${OUT}/linux-${arch}-gnu
    mv detect ${OUT}/linux-${arch}-gnu/
done

# Windows
$ZIG cc -target x86_64-windows-gnu \
    -O2 \
    -I${INCLUDE} \
    -L${LIB}/windows-x86_64 \
    ${SRCS} -lqemount -lunwind \
    -o detect.exe
mkdir -p ${OUT}/windows-x86_64
mv detect.exe ${OUT}/windows-x86_64/

# macOS
for arch in x86_64 aarch64; do
    $ZIG cc -target ${arch}-macos \
        -O2 \
        -I${INCLUDE} \
        -L${LIB}/darwin-${arch} \
        ${SRCS} -lqemount -lunwind \
        -o detect
    mkdir -p ${OUT}/darwin-${arch}
    mv detect ${OUT}/darwin-${arch}/
done

echo "Build complete"
