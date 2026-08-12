#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/puredarwin-linux-build.tar.gz
ARCHITECTURE_ARCHIVE=/host/build/sources/architecture-268.tar.gz
COMPILER_RT_ARCHIVE=/host/build/sources/compiler-rt-14.0.6.src.tar.xz
DYLD_ARCHIVE=/host/build/sources/dyld-519.2.2.tar.gz
XNU_ARCHIVE=/host/build/sources/xnu-4570.41.2.tar.gz
LIBC_ARCHIVE=/host/build/sources/libc-1244.30.3.tar.gz
LIBCXX_ARCHIVE=/host/build/sources/libcxx-5.0.0.src.tar.xz
LIBCXXABI_ARCHIVE=/host/build/sources/libcxxabi-5.0.0.src.tar.xz
LIBDISPATCH_ARCHIVE=/host/build/sources/libdispatch-913.30.4.tar.gz
LIBINFO_ARCHIVE=/host/build/sources/libinfo-517.30.1.tar.gz
LIBM_ARCHIVE=/host/build/sources/libm-2026.tar.gz
LIBNOTIFY_ARCHIVE=/host/build/sources/libnotify-172.tar.gz
LIBMALLOC_ARCHIVE=/host/build/sources/libmalloc-140.40.1.tar.gz
LIBPLATFORM_ARCHIVE=/host/build/sources/libplatform-161.20.1.tar.gz
LIBPTHREAD_ARCHIVE=/host/build/sources/libpthread-301.30.1.tar.gz
LIBRESOLV_ARCHIVE=/host/build/sources/libresolv-65.tar.gz
LIBSYSTEM_ARCHIVE=/host/build/sources/libsystem-1252.50.4.tar.gz
LIBUNWIND_ARCHIVE=/host/build/sources/libunwind-5.0.0.src.tar.xz
SYSLOG_ARCHIVE=/host/build/sources/syslog-356.50.1.tar.gz
IOATAFAMILY_ARCHIVE=/host/build/sources/ioatafamily-255.tar.gz
IOPCIFAMILY_ARCHIVE=/host/build/sources/iopcifamily-320.30.2.tar.gz
IOSTORAGEFAMILY_ARCHIVE=/host/build/sources/iostoragefamily-218.30.1.tar.gz
APPLEFILESYSTEMDRIVER_ARCHIVE=/host/build/sources/applefilesystemdriver-23.tar.gz
HFS_ARCHIVE=/host/build/sources/hfs-407.30.1.tar.gz
CACHE_DIR=$QEMOUNT_CACHE_DIR
SOURCE_DIR=$CACHE_DIR/source
DARWIN_SOURCE_DIR=$CACHE_DIR/darwin-17.4
COMPILER_RT_DIR=$CACHE_DIR/compiler-rt
LIBCXX_DIR=$CACHE_DIR/libcxx-5.0.0
LIBCXXABI_DIR=$CACHE_DIR/libcxxabi-5.0.0
LIBUNWIND_DIR=$CACHE_DIR/libunwind-5.0.0
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
extract_source "$ARCHITECTURE_ARCHIVE" "$DARWIN_SOURCE_DIR/architecture" xzf
extract_source "$COMPILER_RT_ARCHIVE" "$COMPILER_RT_DIR" xJf
extract_source "$DYLD_ARCHIVE" "$DARWIN_SOURCE_DIR/dyld" xzf
extract_source "$XNU_ARCHIVE" "$DARWIN_SOURCE_DIR/xnu" xzf
extract_source "$LIBC_ARCHIVE" "$DARWIN_SOURCE_DIR/libc" xzf
extract_source "$LIBCXX_ARCHIVE" "$LIBCXX_DIR" xJf
extract_source "$LIBCXXABI_ARCHIVE" "$LIBCXXABI_DIR" xJf
extract_source "$LIBDISPATCH_ARCHIVE" "$DARWIN_SOURCE_DIR/libdispatch" xzf
extract_source "$LIBINFO_ARCHIVE" "$DARWIN_SOURCE_DIR/Libinfo" xzf
extract_source "$LIBM_ARCHIVE" "$DARWIN_SOURCE_DIR/Libm" xzf
extract_source "$LIBNOTIFY_ARCHIVE" "$DARWIN_SOURCE_DIR/Libnotify" xzf
extract_source "$LIBMALLOC_ARCHIVE" "$DARWIN_SOURCE_DIR/libmalloc" xzf
extract_source "$LIBPLATFORM_ARCHIVE" "$DARWIN_SOURCE_DIR/libplatform" xzf
extract_source "$LIBPTHREAD_ARCHIVE" "$DARWIN_SOURCE_DIR/libpthread" xzf
extract_source "$LIBRESOLV_ARCHIVE" "$DARWIN_SOURCE_DIR/libresolv" xzf
extract_source "$LIBSYSTEM_ARCHIVE" "$DARWIN_SOURCE_DIR/Libsystem" xzf
extract_source "$LIBUNWIND_ARCHIVE" "$LIBUNWIND_DIR" xJf
extract_source "$SYSLOG_ARCHIVE" "$DARWIN_SOURCE_DIR/syslog" xzf
extract_source "$IOATAFAMILY_ARCHIVE" "$DARWIN_SOURCE_DIR/IOATAFamily" xzf
extract_source "$IOPCIFAMILY_ARCHIVE" "$DARWIN_SOURCE_DIR/IOPCIFamily" xzf
extract_source "$IOSTORAGEFAMILY_ARCHIVE" "$DARWIN_SOURCE_DIR/IOStorageFamily" xzf
extract_source "$APPLEFILESYSTEMDRIVER_ARCHIVE" "$DARWIN_SOURCE_DIR/AppleFileSystemDriver" xzf
extract_source "$HFS_ARCHIVE" "$DARWIN_SOURCE_DIR/hfs" xzf

"$SOURCE_DIR/scripts/prepare-external-sources.sh" "$DARWIN_SOURCE_DIR"

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
    -DPUREDARWIN_LIBCXX_SOURCE_DIR="$LIBCXX_DIR" \
    -DPUREDARWIN_LIBCXXABI_SOURCE_DIR="$LIBCXXABI_DIR" \
    -DPUREDARWIN_LIBUNWIND_SOURCE_DIR="$LIBUNWIND_DIR" \
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
    dyld_runtime \
    libsystem_kernel \
    libsystem_platform_firstpass \
    libsystem_pthread_firstpass \
    libsystem_malloc_firstpass \
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

cmake --install "$BUILD_DIR" \
    --prefix "$ROOT_DIR" \
    --component Dyld

cmake --install "$BUILD_DIR" \
    --prefix "$ROOT_DIR" \
    --component BaseSystem

mkdir -p "$OUTPUT_DIR"
tar -czf "$OUTPUT_ARCHIVE" -C "$ROOT_DIR" .
