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
        -L${LIB}/${arch}-linux-musl \
        ${SRCS} -lqemount -lunwind \
        -o detect
    mkdir -p ${OUT}/${arch}-linux-musl
    mv detect ${OUT}/${arch}-linux-musl/
done

# Linux gnu (glibc)
for arch in x86_64 aarch64; do
    $ZIG cc -target ${arch}-linux-gnu \
        -O2 \
        -I${INCLUDE} \
        -L${LIB}/${arch}-linux-gnu \
        ${SRCS} -lqemount -lunwind \
        -o detect
    mkdir -p ${OUT}/${arch}-linux-gnu
    mv detect ${OUT}/${arch}-linux-gnu/
done

# Windows
$ZIG cc -target x86_64-windows-gnu \
    -O2 \
    -I${INCLUDE} \
    -L${LIB}/x86_64-windows \
    ${SRCS} -lqemount -lunwind \
    -o detect.exe
mkdir -p ${OUT}/x86_64-windows
mv detect.exe ${OUT}/x86_64-windows/

# macOS
for arch in x86_64 aarch64; do
    $ZIG cc -target ${arch}-macos \
        -O2 \
        -I${INCLUDE} \
        -L${LIB}/${arch}-darwin \
        ${SRCS} -lqemount -lunwind \
        -o detect
    mkdir -p ${OUT}/${arch}-darwin
    mv detect ${OUT}/${arch}-darwin/
done

echo "Build complete"
