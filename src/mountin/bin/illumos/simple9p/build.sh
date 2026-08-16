#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

source=/work/simple9p
output=/host/build/bin/${OUTPUT_PLATFORM}/simple9p

rm -rf "$source"
mkdir -p "$source" "${output%/*}"
tar -xf /host/build/sources/simple9p-0.6.4.tar.xz \
    -C "$source" --strip-components=1

make -C "$source" release \
    NETWORK=0 STATIC=0 THREAD_LIBS= \
    API_CPPFLAGS="-D_XOPEN_SOURCE=700 -D__EXTENSIONS__ -D_REENTRANT" \
    RELEASE_CFLAGS="-Os -DNDEBUG -DS9_PATH_MAX=1024"

install -m 0755 "$source/build/simple9p" "$output"
/usr/bin/readelf -d "$output" \
    | grep -q 'Shared library: \[libc.so.1\]'
