#!/bin/sh
set -eu

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
sysroot=/opt/illumos/sysroot

exec "$onbld/bin/amd64/ld" \
    -e _start \
    -I /lib/amd64/ld.so.1 \
    -z defs \
    -R /lib/amd64 \
    -L"$sysroot/lib/amd64" \
    "$sysroot/usr/lib/amd64/crt1.o" \
    "$sysroot/usr/lib/amd64/crti.o" \
    "$@" \
    -lc \
    "$sysroot/usr/lib/amd64/crtn.o"
