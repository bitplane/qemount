#!/bin/sh
set -eu

NBARCH=$(cat /tmp/nbarch)
NBMACHINEARCH=$(cat /tmp/nbmachinearch)
NBKERNARCH=$(cat /tmp/nbkernarch)
SOURCE_HASH=$(sha256sum \
    /host/build/sources/netbsd-10.0-src.tgz \
    /host/build/sources/netbsd-10.0-syssrc.tgz \
    /host/build/sources/netbsd-10.0-sharesrc.tgz \
    /host/build/sources/netbsd-10.0-gnusrc.tgz \
    | sha256sum | cut -d ' ' -f 1)
CACHE_DIR=/host/build/cache/netbsd/${BUILD_PLATFORM}/${OUTPUT_ARCH}/10.0
OBJ_DIR=$CACHE_DIR/kernel-v1/${SOURCE_HASH}/obj

cd /usr/src

# The machine configurations are intentionally separate; only the surrounding
# build pipeline is architecture-independent.
case "$NBKERNARCH" in
    amd64) CONFIG=/QEMOUNT ;;
    evbarm) CONFIG=/QEMOUNT.evbarm ;;
    *) echo "Unsupported NetBSD kernel architecture: $NBKERNARCH" >&2; exit 1 ;;
esac
cp "$CONFIG" "/usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT"

# Build the kernel
mkdir -p "$OBJ_DIR"
./build.sh -O "$OBJ_DIR" -T /usr/tools -U -u -j"${JOBS}" \
    -m "$NBARCH" -a "$NBMACHINEARCH" kernel=QEMOUNT

# Copy unstripped kernel (needed for mdsetimage)
OUTPUT_DIR="/host/build/bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel"
mkdir -p "$OUTPUT_DIR"
cp "$OBJ_DIR/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb" \
   "$OUTPUT_DIR/netbsd.gdb"

# Register cache ownership only after the kernel and output both succeeded.
OWNER=netbsd-10.0-kernel-${BUILD_PLATFORM}-${OUTPUT_ARCH}
CACHE_ROOT=$(dirname "$(dirname "$OBJ_DIR")")
for GENERATION in "$CACHE_ROOT"/*; do
    [ -d "$GENERATION" ] && printf '%s\n' "$OWNER" > "$GENERATION/.qemount-generation"
done
MANIFEST_DIR=/host/build/cache/.qemount/manifests
mkdir -p "$MANIFEST_DIR"
MANIFEST_TMP=$MANIFEST_DIR/$OWNER.json.tmp
printf '{"schema":1,"owner":"%s","root":"%s","current":"%s"}\n' \
    "$OWNER" \
    "netbsd/${BUILD_PLATFORM}/${OUTPUT_ARCH}/10.0/kernel-v1" \
    "$SOURCE_HASH" > "$MANIFEST_TMP"
mv "$MANIFEST_TMP" "$MANIFEST_DIR/$OWNER.json"
