#!/bin/sh
set -eu

SIMPLE9P_SOURCE=/work/simple9p
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-haiku
TOOL_PREFIX=/tools/cross-tools-${OUTPUT_ARCH}/bin/${OUTPUT_ARCH}-unknown-haiku-

rm -rf "$SIMPLE9P_SOURCE"
mkdir -p "$SIMPLE9P_SOURCE" "$OUTPUT_DIR"

tar -xf /host/build/sources/simple9p-0.6.2.tar.xz \
    -C "$SIMPLE9P_SOURCE" --strip-components=1

make -C "$SIMPLE9P_SOURCE" \
    NETWORK=0 \
    CC="${TOOL_PREFIX}gcc" \
    CFLAGS="-Os -g0 -DNDEBUG -DS9_PATH_MAX=1024" \
    LDFLAGS= \
    LIBS="build/libixp.a -lpthread"

"${TOOL_PREFIX}strip" --strip-unneeded \
    "$SIMPLE9P_SOURCE/build/simple9p"

"${TOOL_PREFIX}readelf" -h "$SIMPLE9P_SOURCE/build/simple9p" \
    | grep -q "Advanced Micro Devices X86-64"
"${TOOL_PREFIX}readelf" -d "$SIMPLE9P_SOURCE/build/simple9p" \
    | grep -q "Shared library: \\[libroot.so\\]"
if "${TOOL_PREFIX}readelf" -d "$SIMPLE9P_SOURCE/build/simple9p" \
        | grep -q "Shared library: \\[libnetwork.so\\]"; then
    echo "Networkless simple9p unexpectedly links libnetwork" >&2
    exit 1
fi

install -m 755 "$SIMPLE9P_SOURCE/build/simple9p" \
    "$OUTPUT_DIR/simple9p"
