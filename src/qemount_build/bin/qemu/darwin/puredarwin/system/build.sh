#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/puredarwin-linux-build.tar.gz
COMPILER_RT_ARCHIVE=/host/build/sources/compiler-rt-14.0.6.src.tar.xz
SOURCE_HASH=$(sha256sum "$SOURCE_ARCHIVE" | cut -d ' ' -f 1)
COMPILER_RT_HASH=$(sha256sum "$COMPILER_RT_ARCHIVE" | cut -d ' ' -f 1)
CACHE_DIR=$QEMOUNT_CACHE_DIR
SOURCE_DIR=$CACHE_DIR/source
COMPILER_RT_DIR=$CACHE_DIR/compiler-rt
BUILD_DIR=$CACHE_DIR/build-llvm14
ROOT_DIR=$CACHE_DIR/root-llvm14
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system
OUTPUT_ARCHIVE=$OUTPUT_DIR/kernel.tar.gz
BUILD_JOBS=${JOBS:-1}

mkdir -p "$CACHE_DIR"
if [ ! -f "$CACHE_DIR/.source-$SOURCE_HASH" ]; then
    rm -rf "$SOURCE_DIR"
    mkdir -p "$SOURCE_DIR"
    tar --no-same-owner -xzf "$SOURCE_ARCHIVE" \
        -C "$SOURCE_DIR" --strip-components=1
    rm -f "$CACHE_DIR"/.source-*
    touch "$CACHE_DIR/.source-$SOURCE_HASH"
fi

if [ ! -f "$CACHE_DIR/.compiler-rt-$COMPILER_RT_HASH" ]; then
    rm -rf "$COMPILER_RT_DIR"
    mkdir -p "$COMPILER_RT_DIR"
    tar --no-same-owner -xJf "$COMPILER_RT_ARCHIVE" \
        -C "$COMPILER_RT_DIR" --strip-components=1
    rm -f "$CACHE_DIR"/.compiler-rt-*
    touch "$CACHE_DIR/.compiler-rt-$COMPILER_RT_HASH"
fi

# Keep the downloaded source pristine while retaining out-of-tree objects.
git -C "$SOURCE_DIR" reset --hard HEAD
git -C "$SOURCE_DIR" clean -fdx

CC=clang-14 \
CXX=clang++-14 \
AR=llvm-ar-14 \
RANLIB=llvm-ranlib-14 \
NM=llvm-nm-14 \
STRIP=llvm-strip-14 \
cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -Ddsymutil_path=/usr/bin/dsymutil-14 \
    -DKERNEL_BUILD_XNU=1 \
    -DPUREDARWIN_COMPILER_RT_SOURCE_DIR="$COMPILER_RT_DIR" \
    -DPUREDARWIN_TARGET_TRIPLE=x86_64-apple-macos11 \
    -DPUREDARWIN_BUILD_JOBS="$BUILD_JOBS"

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS" --target xnu

rm -rf "$ROOT_DIR"
install -D -m 755 \
    "$BUILD_DIR/src/Kernel/xnu/xnu/System/Library/Kernels/kernel" \
    "$ROOT_DIR/System/Library/Kernels/kernel"

mkdir -p "$OUTPUT_DIR"
tar -czf "$OUTPUT_ARCHIVE" -C "$ROOT_DIR" .
