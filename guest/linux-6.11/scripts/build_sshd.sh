#!/bin/bash
set -euo pipefail

# Arguments
DEFAULT_DROPBEAR_VERSION="2025.87"
DROPBEAR_VERSION="${1:-$DEFAULT_DROPBEAR_VERSION}"
TARGET_ARCH="$2"
CACHE_DIR=$(realpath "$3")
OUTPUT_BINARY_PATH=$(realpath "$4")
CROSS_COMPILE_PREFIX="$5"

# Paths
DROPBEAR_TARBALL_NAME="dropbear-${DROPBEAR_VERSION}.tar.bz2"
DROPBEAR_TARBALL_PATH="${CACHE_DIR}/${DROPBEAR_TARBALL_NAME}"
DROPBEAR_SRC_DIR="${CACHE_DIR}/dropbear-${DROPBEAR_VERSION}"
OUTPUT_DIR=$(dirname "$OUTPUT_BINARY_PATH")

mkdir -p "$CACHE_DIR" "$OUTPUT_DIR"

# Skip if already built
[ -f "$OUTPUT_BINARY_PATH" ] && exit 0

# Extract tarball directly into source dir
rm -rf "$DROPBEAR_SRC_DIR"
mkdir -p "$DROPBEAR_SRC_DIR"
tar -xjf "$DROPBEAR_TARBALL_PATH" --strip-components=1 -C "$DROPBEAR_SRC_DIR"

cd "$DROPBEAR_SRC_DIR"

# Set up build environment
HOST_TRIPLE=${CROSS_COMPILE_PREFIX%-}

export CC="${CROSS_COMPILE_PREFIX}gcc"
export AR="${CROSS_COMPILE_PREFIX}ar"
export RANLIB="${CROSS_COMPILE_PREFIX}ranlib"
export CFLAGS="-Os"
export LDFLAGS="-static"

# Configure and build
./configure --host="$HOST_TRIPLE" --disable-zlib
make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1

# Copy result
cp dropbearmulti "$OUTPUT_BINARY_PATH"
chmod +x "$OUTPUT_BINARY_PATH"

echo "[sshd] built and copied to $OUTPUT_BINARY_PATH"
