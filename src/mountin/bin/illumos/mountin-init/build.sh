#!/bin/sh
set -eu

test "$MOUNTIN_TARGET_ARCH" = x86_64

output=/host/build/bin/${MOUNTIN_TARGET_PLATFORM}/mountin-init
bootstrap=/host/build/bin/${MOUNTIN_TARGET_PLATFORM}/mountin-bootstrap
object=/work/mountin-init.o
bootstrap_object=/work/mountin-bootstrap.o

mkdir -p "${output%/*}" /work

"$CC" -Os -c /build/mountin-init.c -o "$object"
"$CC" -o "$output" "$object"
"$STRIP" "$output"

/usr/bin/readelf -d "$output" \
    | grep -q 'Shared library: \[libc.so.1\]'

/usr/bin/gcc \
    -m64 \
    -nostdlib \
    -c /build/mountin-bootstrap.S \
    -o "$bootstrap_object"

"/source/usr/src/tools/proto/root_i386-nd/opt/onbld/bin/amd64/ld" \
    -o "$bootstrap" \
    -e _start \
    -dn \
    -z defs \
    "$bootstrap_object"

/usr/bin/strip --strip-unneeded "$bootstrap"
test -z "$(/usr/bin/readelf -l "$bootstrap" | grep interpreter || true)"
