#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/puredarwin-linux-build.tar.gz
COMPILER_RT_ARCHIVE=/host/build/sources/compiler-rt-14.0.6.src.tar.xz
CACHE_DIR=$QEMOUNT_CACHE_DIR
SOURCE_DIR=$CACHE_DIR/source
COMPILER_RT_DIR=$CACHE_DIR/compiler-rt
BUILD_DIR=$CACHE_DIR/build-llvm14
ROOT_DIR=$CACHE_DIR/root-llvm14
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system
OUTPUT_ARCHIVE=$OUTPUT_DIR/kernel.tar.gz
BUILD_JOBS=${JOBS:-1}

mkdir -p "$CACHE_DIR"
extract_source() {
    archive=$1
    destination=$2
    compression=$3
    [ -d "$destination" ] && return 0
    temporary=$destination.tmp.$$
    rm -rf "$temporary"
    mkdir -p "$temporary"
    tar --no-same-owner "-$compression" "$archive" \
        -C "$temporary" --strip-components=1
    mv "$temporary" "$destination"
}

extract_source "$SOURCE_ARCHIVE" "$SOURCE_DIR" xzf
extract_source "$COMPILER_RT_ARCHIVE" "$COMPILER_RT_DIR" xJf

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
