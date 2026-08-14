#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
sysroot=/opt/illumos/sysroot
output=/host/build/bin/${OUTPUT_PLATFORM}/qemount-init
bootstrap=/host/build/bin/${OUTPUT_PLATFORM}/qemount-bootstrap
object=/work/qemount-init.o
bootstrap_object=/work/qemount-bootstrap.o

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
    -c /build/qemount-init.c \
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

/usr/bin/readelf -d "$output" \
    | grep -q 'Shared library: \[libc.so.1\]'

/usr/bin/gcc \
    -m64 \
    -nostdlib \
    -c /build/qemount-bootstrap.S \
    -o "$bootstrap_object"

"$onbld/bin/amd64/ld" \
    -o "$bootstrap" \
    -e _start \
    -dn \
    -z defs \
    "$bootstrap_object"

/usr/bin/strip --strip-unneeded "$bootstrap"
test -z "$(/usr/bin/readelf -l "$bootstrap" | grep interpreter || true)"
