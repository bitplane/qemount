#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/puredarwin-linux-build.tar.gz
XNU_ARCHIVE=/host/build/sources/xnu-4570.41.2.tar.gz
COMPILER_RT_ARCHIVE=/host/build/sources/compiler-rt-14.0.6.src.tar.xz
LIBDISPATCH_ARCHIVE=/host/build/sources/libdispatch-913.30.4.tar.gz
LIBPLATFORM_ARCHIVE=/host/build/sources/libplatform-161.20.1.tar.gz
BOOTSTRAP_CMDS_ARCHIVE=/host/build/sources/bootstrap_cmds-98.tar.gz
SOURCE_HASH=$(sha256sum "$SOURCE_ARCHIVE" | cut -d ' ' -f 1)
XNU_HASH=$(sha256sum "$XNU_ARCHIVE" | cut -d ' ' -f 1)
COMPILER_RT_HASH=$(sha256sum "$COMPILER_RT_ARCHIVE" | cut -d ' ' -f 1)
LIBDISPATCH_HASH=$(sha256sum "$LIBDISPATCH_ARCHIVE" | cut -d ' ' -f 1)
LIBPLATFORM_HASH=$(sha256sum "$LIBPLATFORM_ARCHIVE" | cut -d ' ' -f 1)
BOOTSTRAP_CMDS_HASH=$(sha256sum "$BOOTSTRAP_CMDS_ARCHIVE" | cut -d ' ' -f 1)
INPUT_HASH=$(printf '%s\n' \
    "$SOURCE_HASH" \
    "$XNU_HASH" \
    "$COMPILER_RT_HASH" \
    "$LIBDISPATCH_HASH" \
    "$LIBPLATFORM_HASH" \
    "$BOOTSTRAP_CMDS_HASH" | sha256sum | cut -d ' ' -f 1)
CACHE_DIR=/host/build/cache/puredarwin/${ARCH}/darwin-17/system-v1/${INPUT_HASH}
SOURCE_DIR=$CACHE_DIR/source
COMPILER_RT_DIR=$CACHE_DIR/compiler-rt/${COMPILER_RT_HASH}
LIBDISPATCH_DIR=$CACHE_DIR/libdispatch/${LIBDISPATCH_HASH}
LIBPLATFORM_DIR=$CACHE_DIR/libplatform/${LIBPLATFORM_HASH}
BOOTSTRAP_CMDS_DIR=$CACHE_DIR/bootstrap_cmds/${BOOTSTRAP_CMDS_HASH}
RUNTIME_BUILD_DIR=$CACHE_DIR/runtime-build-llvm14
BUILD_DIR=$CACHE_DIR/build-llvm14
ROOT_DIR=$CACHE_DIR/root-llvm14
OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-darwin/puredarwin/system
OUTPUT_ARCHIVE=$OUTPUT_DIR/kernel.tar.gz
BUILD_JOBS=${JOBS:-1}

mkdir -p "$SOURCE_DIR" "$BUILD_DIR"
if [ ! -f "$CACHE_DIR/.source-unpacked" ]; then
    tar --no-same-owner -xzf "$SOURCE_ARCHIVE" \
        -C "$SOURCE_DIR" --strip-components=1
    touch "$CACHE_DIR/.source-unpacked"
fi

if [ ! -f "$COMPILER_RT_DIR/.source-unpacked" ]; then
    mkdir -p "$COMPILER_RT_DIR"
    tar --no-same-owner -xJf "$COMPILER_RT_ARCHIVE" \
        -C "$COMPILER_RT_DIR" --strip-components=1
    touch "$COMPILER_RT_DIR/.source-unpacked"
fi

if [ ! -f "$LIBDISPATCH_DIR/.source-unpacked" ]; then
    mkdir -p "$LIBDISPATCH_DIR"
    tar --no-same-owner -xzf "$LIBDISPATCH_ARCHIVE" \
        -C "$LIBDISPATCH_DIR" --strip-components=1
    touch "$LIBDISPATCH_DIR/.source-unpacked"
fi

if [ ! -f "$LIBPLATFORM_DIR/.source-unpacked" ]; then
    mkdir -p "$LIBPLATFORM_DIR"
    tar --no-same-owner -xzf "$LIBPLATFORM_ARCHIVE" \
        -C "$LIBPLATFORM_DIR" --strip-components=1
    touch "$LIBPLATFORM_DIR/.source-unpacked"
fi

if [ ! -f "$BOOTSTRAP_CMDS_DIR/.source-unpacked" ]; then
    mkdir -p "$BOOTSTRAP_CMDS_DIR"
    tar --no-same-owner -xzf "$BOOTSTRAP_CMDS_ARCHIVE" \
        -C "$BOOTSTRAP_CMDS_DIR" --strip-components=1
    touch "$BOOTSTRAP_CMDS_DIR/.source-unpacked"
fi

# Keep the downloaded source pristine. The build objects remain in BUILD_DIR
# across iterations.
git -C "$SOURCE_DIR" reset --hard HEAD
git -C "$SOURCE_DIR" clean -fdx
# Use the MIG generator paired with XNU 4570. The current generator emits
# calls to kernel helpers that do not exist in Darwin 17.
cp -p "$BOOTSTRAP_CMDS_DIR"/migcom.tproj/*.c \
    "$BOOTSTRAP_CMDS_DIR"/migcom.tproj/*.h \
    "$BOOTSTRAP_CMDS_DIR"/migcom.tproj/lexxer.l \
    "$BOOTSTRAP_CMDS_DIR"/migcom.tproj/parser.y \
    "$SOURCE_DIR/tools/mig/"
git -C "$LIBDISPATCH_DIR" reset --hard HEAD
git -C "$LIBDISPATCH_DIR" clean -fdx
for patch_file in /patches-libdispatch-913/*.patch; do
    git -C "$LIBDISPATCH_DIR" apply "$patch_file"
done

# compiler-rt's profiling runtime builds against the current PureDarwin header
# substrate. Build and cache it before replacing the vendored XNU tree, then
# pass the resulting target archive into the historical kernel build.
CC=clang-14 \
CXX=clang++-14 \
AR=llvm-ar-14 \
RANLIB=llvm-ranlib-14 \
NM=llvm-nm-14 \
STRIP=llvm-strip-14 \
cmake -S "$SOURCE_DIR" -B "$RUNTIME_BUILD_DIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -Ddsymutil_path=/usr/bin/dsymutil-14 \
    -DKERNEL_BUILD_XNU=1 \
    -DPUREDARWIN_COMPILER_RT_SOURCE_DIR="$COMPILER_RT_DIR" \
    -DPUREDARWIN_TARGET_TRIPLE=x86_64-apple-macos11 \
    -DPUREDARWIN_BUILD_JOBS="$BUILD_JOBS"
cmake --build "$RUNTIME_BUILD_DIR" --parallel "$BUILD_JOBS" \
    --target compiler_rt_profile
PROFILE_RUNTIME=$RUNTIME_BUILD_DIR/src/Kernel/libcompiler_rt_profile.a

# PureDarwin provides the Linux/CMake integration, while the kernel sources are
# pinned independently to the Darwin version used by the guest. Preserve only
# that integration when replacing the newer vendored XNU tree.
XNU_CMAKE_DIR=$CACHE_DIR/xnu-cmake
rm -rf "$XNU_CMAKE_DIR"
mkdir -p "$XNU_CMAKE_DIR"
cp "$SOURCE_DIR/src/Kernel/xnu/CMakeLists.txt" \
    "$SOURCE_DIR/src/Kernel/xnu/preprocess_files.cmake" \
    "$XNU_CMAKE_DIR/"
cp -a "$SOURCE_DIR/src/Kernel/xnu/cmake" "$XNU_CMAKE_DIR/"

rm -rf "$SOURCE_DIR/src/Kernel/xnu"
mkdir -p "$SOURCE_DIR/src/Kernel/xnu"
tar --no-same-owner -xzf "$XNU_ARCHIVE" \
    -C "$SOURCE_DIR/src/Kernel/xnu" --strip-components=1
cp "$XNU_CMAKE_DIR/CMakeLists.txt" \
    "$XNU_CMAKE_DIR/preprocess_files.cmake" \
    "$SOURCE_DIR/src/Kernel/xnu/"
cp -a "$XNU_CMAKE_DIR/cmake" "$SOURCE_DIR/src/Kernel/xnu/"
for patch_file in /patches-xnu-4570/*.patch; do
    git -C "$SOURCE_DIR" apply "$patch_file"
done

# PureDarwin tracks current libdispatch, but its kernel firehose must match the
# structures exported by the selected XNU. macOS 10.13.3 pairs these releases.
FIREHOSE_DIR=$SOURCE_DIR/src/Kernel/libfirehose_kernel
cp "$LIBDISPATCH_DIR/src/firehose/firehose_buffer.c" \
    "$LIBDISPATCH_DIR/src/firehose/firehose_buffer_internal.h" \
    "$LIBDISPATCH_DIR/src/firehose/firehose_inline_internal.h" \
    "$LIBDISPATCH_DIR/src/firehose/firehose_internal.h" \
    "$FIREHOSE_DIR/src/"
cp "$LIBDISPATCH_DIR/os/firehose_buffer_private.h" \
    "$FIREHOSE_DIR/include/os/"
mkdir -p "$FIREHOSE_DIR/include/internal"
cp "$LIBPLATFORM_DIR/private/os/internal/atomic.h" \
    "$FIREHOSE_DIR/include/internal/"

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
    -DPUREDARWIN_COMPILER_RT_SOURCE_DIR= \
    -DPUREDARWIN_PROFILE_RUNTIME_LIBRARY="$PROFILE_RUNTIME" \
    -DPUREDARWIN_TARGET_TRIPLE=x86_64-apple-macos11 \
    -DPUREDARWIN_BUILD_JOBS="$BUILD_JOBS"

cmake --build "$BUILD_DIR" --parallel "$BUILD_JOBS" --target xnu

rm -rf "$ROOT_DIR"
install -D -m 755 \
    "$BUILD_DIR/src/Kernel/xnu/xnu/System/Library/Kernels/kernel" \
    "$ROOT_DIR/System/Library/Kernels/kernel"

mkdir -p "$OUTPUT_DIR"
tar -czf "$OUTPUT_ARCHIVE" -C "$ROOT_DIR" .
