#!/bin/sh
set -eu

CC=/opt/aros-toolchain/i386-aros-gcc
AR=/opt/aros-toolchain/i386-aros-ar
STRIP=/opt/aros-toolchain/i386-aros-strip
SDK=/work/sdk/Developer
SIMPLE9P_SOURCE=/work/simple9p-source
LIBIXP_SOURCE=$SIMPLE9P_SOURCE/libixp
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-aros
CFLAGS="--sysroot=$SDK -Os -fno-common -fno-asynchronous-unwind-tables -fno-unwind-tables -DVERSION=\"0.5\" -D_POSIX_C_SOURCE=200809L -DSIMPLE9P_NO_NETWORK -DS9_PATH_MAX=1024 -I$LIBIXP_SOURCE/include"

mkdir -p \
    /work/sdk /work/objects/libixp \
    "$SIMPLE9P_SOURCE" "$OUTPUT_DIR"
tar -xzf /host/build/lib/${OUTPUT_ARCH}-aros/sdk.tar.gz -C /work/sdk
tar -xf /host/build/sources/simple9p-0.6.1.tar.xz \
    -C "$SIMPLE9P_SOURCE" --strip-components=1

for name in \
    convert error map message request rpc server srv_util thread timer \
    transport util
do
    "$CC" $CFLAGS -c "$LIBIXP_SOURCE/lib/libixp/$name.c" \
        -o "/work/objects/libixp/$name.o"
done
"$AR" rcs /work/objects/libixp.a /work/objects/libixp/*.o

for name in \
    simple9p alloc path namespace platform_amiga \
    fs_dir fs_io fs_ops fs_stat
do
    "$CC" $CFLAGS -c "$SIMPLE9P_SOURCE/$name.c" \
        -o "/work/objects/$name.o"
done

"$CC" --sysroot="$SDK" -Wl,-Map,/work/objects/simple9p.map \
    -o /work/objects/simple9p \
    /work/objects/simple9p.o \
    /work/objects/alloc.o \
    /work/objects/path.o \
    /work/objects/namespace.o \
    /work/objects/platform_amiga.o \
    /work/objects/fs_dir.o \
    /work/objects/fs_io.o \
    /work/objects/fs_ops.o \
    /work/objects/fs_stat.o \
    /work/objects/libixp.a

"$STRIP" --strip-unneeded -R.comment /work/objects/simple9p
cp /work/objects/simple9p "$OUTPUT_DIR/simple9p"
