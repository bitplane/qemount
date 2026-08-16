#!/bin/sh
set -eu

NINED_SOURCE=/work/9d
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-haiku

rm -rf "$NINED_SOURCE"
mkdir -p "$NINED_SOURCE" "$OUTPUT_DIR"

tar -xf /host/build/sources/9d-0.7.0.tar.xz \
    -C "$NINED_SOURCE" --strip-components=1

make -C "$NINED_SOURCE" release \
    NETWORK=0 \
    STATIC=0 \
    STRIP="$STRIP --strip-unneeded" \
    RELEASE_CFLAGS="-Os -g0 -DNDEBUG -DS9_PATH_MAX=1024" \
    THREAD_LIBS=

"$READELF" -h "$NINED_SOURCE/build/9d" \
    | grep -q "Advanced Micro Devices X86-64"
"$READELF" -d "$NINED_SOURCE/build/9d" \
    | grep -q "Shared library: \\[libroot.so\\]"
if "$READELF" -d "$NINED_SOURCE/build/9d" \
        | grep -q "Shared library: \\[libnetwork.so\\]"; then
    echo "Networkless 9d unexpectedly links libnetwork" >&2
    exit 1
fi

install -m 755 "$NINED_SOURCE/build/9d" \
    "$OUTPUT_DIR/9d"
