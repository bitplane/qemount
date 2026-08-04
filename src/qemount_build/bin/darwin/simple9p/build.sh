#!/bin/sh
set -eu

SDK_ARCHIVE=/host/build/sources/MacOSX11.3.sdk.tar.xz
SDK_HASH=$(sha256sum "$SDK_ARCHIVE" | cut -d ' ' -f 1)
SDK_CACHE=/host/build/cache/darwin/sdk/$SDK_HASH
SDK=$SDK_CACHE/MacOSX11.3.sdk
SOURCE=/work/simple9p
LIBIXP=$SOURCE/libixp
OBJECTS=/work/objects
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-darwin
TARGET=x86_64-apple-macos10.13

if [ ! -d "$SDK" ]; then
    mkdir -p "$SDK_CACHE"
    tar --no-same-owner -xJf "$SDK_ARCHIVE" -C "$SDK_CACHE"
fi

rm -rf "$SOURCE" "$OBJECTS"
mkdir -p "$LIBIXP" "$OBJECTS/libixp" "$OUTPUT_DIR"
tar -xf /host/build/sources/simple9p-0.6.1.tar.xz \
    -C "$SOURCE" --strip-components=1

CC="clang-14 --target=$TARGET -isysroot $SDK -mmacosx-version-min=10.13"
CFLAGS="-Os -g0 -D_XOPEN_SOURCE=600 -DSIMPLE9P_NO_NETWORK -DS9_PATH_MAX=1024"
INCLUDES="-I$SOURCE -I$LIBIXP/include"

for name in convert error map message request rpc server socket transport util \
        timer client thread; do
    $CC $CFLAGS $INCLUDES -c "$LIBIXP/lib/libixp/$name.c" \
        -o "$OBJECTS/libixp/$name.o"
done
llvm-ar-14 rcs "$OBJECTS/libixp.a" "$OBJECTS"/libixp/*.o

for name in simple9p alloc path namespace platform_posix fs_ops fs_io fs_stat fs_dir; do
    $CC $CFLAGS $INCLUDES -c "$SOURCE/$name.c" -o "$OBJECTS/$name.o"
done

$CC -fuse-ld=lld -Wl,-dead_strip -o "$OBJECTS/simple9p" \
    "$OBJECTS"/simple9p.o \
    "$OBJECTS"/alloc.o \
    "$OBJECTS"/path.o \
    "$OBJECTS"/namespace.o \
    "$OBJECTS"/platform_posix.o \
    "$OBJECTS"/fs_ops.o \
    "$OBJECTS"/fs_io.o \
    "$OBJECTS"/fs_stat.o \
    "$OBJECTS"/fs_dir.o \
    "$OBJECTS/libixp.a" \
    -lpthread

llvm-strip-14 -S "$OBJECTS/simple9p"
llvm-objdump-14 --macho --private-headers "$OBJECTS/simple9p" \
    | grep -Eq 'LC_(BUILD_VERSION|VERSION_MIN_MACOSX)'
install -m 755 "$OBJECTS/simple9p" "$OUTPUT_DIR/simple9p"

$CC $CFLAGS -fuse-ld=lld -Wl,-dead_strip -o "$OBJECTS/stream64" \
    /stream64.c -lpthread
llvm-strip-14 -S "$OBJECTS/stream64"
install -m 755 "$OBJECTS/stream64" "$OUTPUT_DIR/stream64"
