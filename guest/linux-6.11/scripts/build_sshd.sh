#!/bin/bash
set -euo pipefail

# --- Script Arguments ---
DEFAULT_DROPBEAR_VERSION="2025.87"
DROPBEAR_VERSION="${1:-$DEFAULT_DROPBEAR_VERSION}"
TARGET_ARCH="$2"
CACHE_DIR=$(realpath "$3")
OUTPUT_BINARY_PATH=$(realpath "$4")
CROSS_COMPILE_PREFIX="$5"

# --- Setup Paths ---
DROPBEAR_TARBALL_NAME="dropbear-${DROPBEAR_VERSION}.tar.bz2"
DROPBEAR_TARBALL_PATH="${CACHE_DIR}/${DROPBEAR_TARBALL_NAME}"
DROPBEAR_SRC_DIR="${CACHE_DIR}/dropbear-${DROPBEAR_VERSION}"
DROPBEAR_URL="https://matt.ucc.asn.au/dropbear/releases/${DROPBEAR_TARBALL_NAME}"
OUTPUT_DIR=$(dirname "$OUTPUT_BINARY_PATH")

mkdir -p "$CACHE_DIR"
mkdir -p "$OUTPUT_DIR"

# --- Download ---
if [ ! -f "$DROPBEAR_TARBALL_PATH" ]; then
    echo "Downloading dropbear ${DROPBEAR_VERSION} from ${DROPBEAR_URL}..."
    wget --connect-timeout=10 --tries=3 -c "$DROPBEAR_URL" -O "$DROPBEAR_TARBALL_PATH"
else
    echo "Using cached dropbear tarball: $DROPBEAR_TARBALL_PATH"
fi

# --- Extract ---
rm -rf "$DROPBEAR_SRC_DIR"
echo "Extracting dropbear source to $DROPBEAR_SRC_DIR..."
mkdir -p "$DROPBEAR_SRC_DIR"
tar -xjf "$DROPBEAR_TARBALL_PATH" --strip-components=1 -C "$DROPBEAR_SRC_DIR"

cd "$DROPBEAR_SRC_DIR"

# --- Configure ---
echo "Configuring and building dropbear statically for ${TARGET_ARCH}..."

HOST_TRIPLE=${CROSS_COMPILE_PREFIX%-}

if [ -z "$HOST_TRIPLE" ]; then
    echo "Warning: CROSS_COMPILE_PREFIX is empty, attempting native build configure."
fi

# Dropbear uses a custom `configure` script, not autotools
make distclean || true

# Build with static flags
export CC="${CROSS_COMPILE_PREFIX}gcc"
export AR="${CROSS_COMPILE_PREFIX}ar"
export RANLIB="${CROSS_COMPILE_PREFIX}ranlib"
export STRIP="${CROSS_COMPILE_PREFIX}strip"
export CFLAGS="-Os -static"
export LDFLAGS="-static"

./configure --host="$HOST_TRIPLE" --disable-zlib

echo "Running make..."
make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1

# --- Copy Output ---
# dropbear builds a multi-call binary by default if MULTI=1
BUILT_BINARY_PATH="${DROPBEAR_SRC_DIR}/dropbearmulti"

if [ ! -f "$BUILT_BINARY_PATH" ]; then
    echo "Error: Built dropbear binary not found at $BUILT_BINARY_PATH" >&2
    exit 1
fi

echo "Copying built dropbear binary to $OUTPUT_BINARY_PATH"
cp "$BUILT_BINARY_PATH" "$OUTPUT_BINARY_PATH"
chmod +x "$OUTPUT_BINARY_PATH"

echo "build_dropbear.sh finished successfully."
exit 0
