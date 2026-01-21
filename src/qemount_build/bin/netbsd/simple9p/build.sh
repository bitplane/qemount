#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
NBGNUTRIPLE=$(cat /tmp/nbgnutriple)
SYSROOT=/usr/obj/destdir.$NBARCH
CC="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc"
AR="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-ar"
STRIP="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip"

cd /work

# Extract sources
tar -xf /host/build/sources/simple9p-qemount-0.1.tar.gz
tar -xf /host/build/sources/libixp-qemount-0.1.tar.gz

# Build libixp
cd /work/libixp-qemount-0.1
mkdir -p install/lib install/include
CFLAGS="--sysroot=$SYSROOT -Iinclude -DVERSION=\"0.5\" -D_POSIX_C_SOURCE=200809L"
for f in lib/libixp/*.c; do
    echo "Compiling $f..."
    $CC $CFLAGS -c -o "${f%.c}.o" "$f"
done
$AR rcs install/lib/libixp.a lib/libixp/*.o
cp include/ixp.h install/include/

# Build simple9p
cd /work/simple9p-qemount-0.1
LIBIXP=/work/libixp-qemount-0.1/install
$CC --sysroot=$SYSROOT -static -I$LIBIXP/include -o simple9p simple9p.c path.c fs_dir.c fs_io.c fs_ops.c fs_stat.c -L$LIBIXP/lib -lixp
$STRIP simple9p

# Copy to output
mkdir -p /host/build/bin/${ARCH}-netbsd
cp -v simple9p /host/build/bin/${ARCH}-netbsd/
