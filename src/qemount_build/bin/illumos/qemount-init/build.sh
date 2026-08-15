#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

output=/host/build/bin/${OUTPUT_PLATFORM}/qemount-init
bootstrap=/host/build/bin/${OUTPUT_PLATFORM}/qemount-bootstrap
object=/work/qemount-init.o
bootstrap_object=/work/qemount-bootstrap.o

mkdir -p "${output%/*}" /work

"$CC" -Os -c /build/qemount-init.c -o "$object"
"$CC" -o "$output" "$object"
"$STRIP" "$output"

/usr/bin/readelf -d "$output" \
    | grep -q 'Shared library: \[libc.so.1\]'

/usr/bin/gcc \
    -m64 \
    -nostdlib \
    -c /build/qemount-bootstrap.S \
    -o "$bootstrap_object"

"/source/usr/src/tools/proto/root_i386-nd/opt/onbld/bin/amd64/ld" \
    -o "$bootstrap" \
    -e _start \
    -dn \
    -z defs \
    "$bootstrap_object"

/usr/bin/strip --strip-unneeded "$bootstrap"
test -z "$(/usr/bin/readelf -l "$bootstrap" | grep interpreter || true)"
