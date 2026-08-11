#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/puredarwin-linux-build.tar.gz
COMPILER_RT_ARCHIVE=/host/build/sources/compiler-rt-14.0.6.src.tar.xz
XNU_ARCHIVE=/host/build/sources/xnu-4570.41.2.tar.gz
LIBC_ARCHIVE=/host/build/sources/libc-1244.30.3.tar.gz
LIBDISPATCH_ARCHIVE=/host/build/sources/libdispatch-913.30.4.tar.gz
LIBMALLOC_ARCHIVE=/host/build/sources/libmalloc-140.40.1.tar.gz
LIBPLATFORM_ARCHIVE=/host/build/sources/libplatform-161.20.1.tar.gz
LIBPTHREAD_ARCHIVE=/host/build/sources/libpthread-301.30.1.tar.gz
IOATAFAMILY_ARCHIVE=/host/build/sources/ioatafamily-255.tar.gz
IOPCIFAMILY_ARCHIVE=/host/build/sources/iopcifamily-320.30.2.tar.gz
IOSTORAGEFAMILY_ARCHIVE=/host/build/sources/iostoragefamily-218.30.1.tar.gz
APPLEFILESYSTEMDRIVER_ARCHIVE=/host/build/sources/applefilesystemdriver-23.tar.gz
HFS_ARCHIVE=/host/build/sources/hfs-407.30.1.tar.gz
CACHE_DIR=$QEMOUNT_CACHE_DIR
SOURCE_DIR=$CACHE_DIR/source
DARWIN_SOURCE_DIR=$CACHE_DIR/darwin-17.4
COMPILER_RT_DIR=$CACHE_DIR/compiler-rt
BUILD_DIR=$CACHE_DIR/build-llvm14
ROOT_DIR=$CACHE_DIR/root-llvm14
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system
OUTPUT_ARCHIVE=$OUTPUT_DIR/base-system.tar.gz
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
extract_source "$XNU_ARCHIVE" "$DARWIN_SOURCE_DIR/xnu" xzf
extract_source "$LIBC_ARCHIVE" "$DARWIN_SOURCE_DIR/libc" xzf
extract_source "$LIBDISPATCH_ARCHIVE" "$DARWIN_SOURCE_DIR/libdispatch" xzf
extract_source "$LIBMALLOC_ARCHIVE" "$DARWIN_SOURCE_DIR/libmalloc" xzf
extract_source "$LIBPLATFORM_ARCHIVE" "$DARWIN_SOURCE_DIR/libplatform" xzf
extract_source "$LIBPTHREAD_ARCHIVE" "$DARWIN_SOURCE_DIR/libpthread" xzf
extract_source "$IOATAFAMILY_ARCHIVE" "$DARWIN_SOURCE_DIR/IOATAFamily" xzf
extract_source "$IOPCIFAMILY_ARCHIVE" "$DARWIN_SOURCE_DIR/IOPCIFamily" xzf
extract_source "$IOSTORAGEFAMILY_ARCHIVE" "$DARWIN_SOURCE_DIR/IOStorageFamily" xzf
extract_source "$APPLEFILESYSTEMDRIVER_ARCHIVE" "$DARWIN_SOURCE_DIR/AppleFileSystemDriver" xzf
extract_source "$HFS_ARCHIVE" "$DARWIN_SOURCE_DIR/hfs" xzf

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
    -DPUREDARWIN_EXTERNAL_SOURCE_ROOT="$DARWIN_SOURCE_DIR" \
    -DPUREDARWIN_TARGET_TRIPLE=x86_64-apple-macos11 \
    -DPUREDARWIN_BUILD_JOBS="$BUILD_JOBS"

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS" --target \
    xnu \
    AppleAPIC \
    AppleI386GenericPlatform \
    AppleIntelPIIXATA \
    IOACPIFamily \
    IOATAFamily \
    IOPCIFamily \
    IOStorageFamily \
    AppleFileSystemDriver \
    HFS \
    HFSEncodings \
    corecrypto.kext \
    pthread.kext

rm -rf "$ROOT_DIR"
install -D -m 755 \
    "$BUILD_DIR/src/Kernel/xnu/xnu/System/Library/Kernels/kernel" \
    "$ROOT_DIR/System/Library/Kernels/kernel"

for extension in \
    AppleAPIC \
    AppleI386GenericPlatform \
    AppleIntelPIIXATA \
    IOACPIFamily \
    IOATAFamily \
    IOPCIFamily \
    IOStorageFamily \
    AppleFileSystemDriver \
    HFS \
    HFSEncodings \
    corecrypto \
    pthread
do
    cmake --install "$BUILD_DIR" \
        --prefix "$ROOT_DIR" \
        --component "KernelExtension-$extension"
done

mkdir -p "$OUTPUT_DIR"
tar -czf "$OUTPUT_ARCHIVE" -C "$ROOT_DIR" .
