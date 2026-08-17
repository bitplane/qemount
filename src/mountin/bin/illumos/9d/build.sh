#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

source=/work/9d
output=/host/build/bin/${OUTPUT_PLATFORM}/9d

rm -rf "$source"
mkdir -p "$source" "${output%/*}"
tar -xf /host/build/sources/9d-0.7.1.tar.xz \
    -C "$source" --strip-components=1

make -C "$source" release \
    NETWORK=0 STATIC=0 THREAD_LIBS= \
    API_CPPFLAGS="-D_XOPEN_SOURCE=700 -D__EXTENSIONS__ -D_REENTRANT" \
    RELEASE_CFLAGS="-Os -DNDEBUG -DS9_PATH_MAX=1024"

install -m 0755 "$source/build/9d" "$output"
/usr/bin/readelf -d "$output" \
    | grep -q 'Shared library: \[libc.so.1\]'
