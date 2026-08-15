#!/bin/sh
set -eu

SIMPLE9P_SOURCE=/work/simple9p
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-haiku
TOOL_PREFIX=/toolchains/cross-tools-${OUTPUT_ARCH}/bin/${OUTPUT_ARCH}-unknown-haiku-
SYSROOT=/opt/haiku-sysroot

rm -rf "$SIMPLE9P_SOURCE"
mkdir -p "$SIMPLE9P_SOURCE" "$OUTPUT_DIR"

tar -xf /host/build/sources/simple9p-0.6.3.tar.xz \
    -C "$SIMPLE9P_SOURCE" --strip-components=1

make -C "$SIMPLE9P_SOURCE" release \
    NETWORK=0 \
    STATIC=0 \
    CC="${TOOL_PREFIX}gcc --sysroot=${SYSROOT}" \
    AR="${TOOL_PREFIX}ar" \
    STRIP="${TOOL_PREFIX}strip --strip-unneeded" \
    RELEASE_CFLAGS="-Os -g0 -DNDEBUG -DS9_PATH_MAX=1024" \
    LDFLAGS="--sysroot=${SYSROOT}" \
    THREAD_LIBS=

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
