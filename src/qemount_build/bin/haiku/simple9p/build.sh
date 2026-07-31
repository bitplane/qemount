#!/bin/sh
set -eu

SIMPLE9P_SOURCE=/work/simple9p
OUTPUT_DIR=/host/build/bin/${ARCH}-haiku
TOOL_PREFIX=/tools/cross-tools-${ARCH}/bin/${ARCH}-unknown-haiku-

rm -rf "$SIMPLE9P_SOURCE"
mkdir -p "$SIMPLE9P_SOURCE/libixp" "$OUTPUT_DIR"

tar -xzf /host/build/sources/simple9p-qemount-0.5.tar.gz \
    -C "$SIMPLE9P_SOURCE" --strip-components=1
tar -xzf /host/build/sources/libixp-qemount-0.2.tar.gz \
    -C "$SIMPLE9P_SOURCE/libixp" --strip-components=1

make -C "$SIMPLE9P_SOURCE" \
    NETWORK=0 \
    CC="${TOOL_PREFIX}gcc" \
    CFLAGS="-Os -g0" \
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
