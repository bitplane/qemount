#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
sysroot=/host/build/bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
output=/host/build/bin/${OUTPUT_PLATFORM}/ufs-fixture-init
object=/work/ufs-fixture-init.o

mkdir -p "${output%/*}" /work

"$onbld/bin/i386/cw" \
    --tag target \
    --linker "$onbld/bin/amd64/ld" \
    --primary gcc12,/usr/bin/gcc,gnu \
    -- \
    -m64 \
    -_gcc=-Os \
    -_gcc=-fno-stack-protector \
    -_gcc=-nostdinc \
    -xc99=%all \
    -I"$sysroot/usr/include" \
    -c /build/ufs-fixture-init.c \
    -o "$object"

"$onbld/bin/amd64/ld" \
    -o "$output" \
    -e _start \
    -I /lib/amd64/ld.so.1 \
    -z defs \
    -R /lib/amd64 \
    -L"$sysroot/lib/amd64" \
    "$sysroot/usr/lib/amd64/crt1.o" \
    "$sysroot/usr/lib/amd64/crti.o" \
    "$object" \
    -lc \
    "$sysroot/usr/lib/amd64/crtn.o"

/usr/bin/strip --strip-unneeded "$output"
