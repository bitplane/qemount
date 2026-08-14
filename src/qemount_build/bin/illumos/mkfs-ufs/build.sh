#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
makefile=$src/cmd/make/bin/make.rules.file
sysroot=/host/build/bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
output=/host/build/bin/${OUTPUT_PLATFORM}/mkfs.ufs

rm -rf /proto
cp -a "$sysroot" /proto
cd "$src/cmd/fs.d/ufs/mkfs"
mkdir -p "$onbld/bin/amd64"
ln -sf ../i386/cw "$onbld/bin/amd64/cw"
dmake -r -f "$makefile" -f Makefile \
    "MAKE=dmake -r -f $makefile -f Makefile" \
    SRC="$src" CODEMGR_WS=/source \
    MACH=amd64 MACH64=amd64 NATIVE_MACH=amd64 NATIVE_MACH64=amd64 \
    RELEASE_BUILD= NATIVE_OS=linux \
    GNU_ROOT=/opt/illumos-binutils GNUC_ROOT=/usr NATIVE_GNUC_ROOT=/usr \
    ONBLD_TOOLS="$onbld" ROOT=/proto \
    "ENVCPPFLAGS1=-I/proto/usr/include -I$src/uts/intel -Dllseek=qemount_llseek -Daiowrite=qemount_aiowrite -Daiowait=qemount_aiowait" \
    ENVLDLIBS1=-L/proto/lib ENVLDLIBS2=-L/proto/usr/lib \
    "CERRWARN=-_gcc=-Wno-unknown-pragmas -_gcc=-Wno-incompatible-pointer-types" \
    mkfs.o fslib.o

"$onbld/bin/i386/cw" \
    --tag target \
    --linker "$onbld/bin/amd64/ld" \
    --primary gcc12,/usr/bin/gcc,gnu \
    -- \
    -m64 -xc99=%all -D__sun -D__SVR4 -I/proto/usr/include \
    -c /build/mkfs-stubs.c -o /build/mkfs-stubs.o

"$onbld/bin/amd64/ld" \
    -o "$output" \
    -I /lib/amd64/ld.so.1 \
    -R /lib/amd64 \
    -L/proto/lib/amd64 -L/proto/usr/lib/amd64 \
    /proto/usr/lib/amd64/crt1.o /proto/usr/lib/amd64/crti.o \
    mkfs.o fslib.o /build/mkfs-stubs.o \
    -lc \
    /proto/usr/lib/amd64/crtn.o

/usr/bin/strip --strip-unneeded "$output"
