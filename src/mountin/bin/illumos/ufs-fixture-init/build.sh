#!/bin/sh
set -eu

test "$MOUNTIN_TARGET_ARCH" = x86_64

output=/host/build/bin/${MOUNTIN_TARGET_PLATFORM}/ufs-fixture-init
object=/work/ufs-fixture-init.o

mkdir -p "${output%/*}" /work

"$CC" -Os -c /build/ufs-fixture-init.c -o "$object"
"$CC" -o "$output" "$object"
"$STRIP" "$output"
