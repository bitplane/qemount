#!/bin/bash
set -euo pipefail

# --- Script Arguments ---
# If DIOD_VERSION is not provided as the first argument, use default.
DEFAULT_DIOD_VERSION="1.0.24"
DIOD_VERSION="${1:-$DEFAULT_DIOD_VERSION}"
TARGET_ARCH="$2"            # e.g., x86_64, arm64
CACHE_DIR=$(realpath "$3")  # Absolute path to cache directory
OUTPUT_BINARY_PATH=$(realpath "$4") # Absolute path for the final binary (e.g., .../staging/bin/diod)
CROSS_COMPILE_PREFIX="$5"   # e.g., x86_64-linux-gnu-

# --- Setup Paths ---
DIOD_TARBALL_NAME="diod-${DIOD_VERSION}.tar.gz"
DIOD_TARBALL_PATH="${CACHE_DIR}/${DIOD_TARBALL_NAME}"
DIOD_SRC_DIR="${CACHE_DIR}/diod-${DIOD_VERSION}"
DIOD_URL="https://github.com/chaos/diod/releases/download/${DIOD_VERSION}/${DIOD_TARBALL_NAME}"
OUTPUT_DIR=$(dirname "$OUTPUT_BINARY_PATH")

# --- Ensure Directories Exist ---
mkdir -p "$CACHE_DIR"
mkdir -p "$OUTPUT_DIR"

# --- Download ---
if [ ! -f "$DIOD_TARBALL_PATH" ]; then
    echo "Downloading diod ${DIOD_VERSION} from ${DIOD_URL}..."
    # Use wget with timeout and retry options for robustness
    wget --connect-timeout=10 --tries=3 -c "$DIOD_URL" -O "$DIOD_TARBALL_PATH"
else
    echo "Using cached diod tarball: $DIOD_TARBALL_PATH"
fi

# --- Extract ---
# Remove previous extraction if it exists to ensure clean source
rm -rf "$DIOD_SRC_DIR"
echo "Extracting diod source to $DIOD_SRC_DIR..."
mkdir -p "$DIOD_SRC_DIR"
tar -xzf "$DIOD_TARBALL_PATH" --strip-components=1 -C "$DIOD_SRC_DIR"

# --- Build ---
echo "Configuring and building diod statically for ${TARGET_ARCH}..."
cd "$DIOD_SRC_DIR"

# Determine the HOST triple for ./configure (usually derived from CROSS_COMPILE_PREFIX)
# Removes the trailing hyphen if present
HOST_TRIPLE=${CROSS_COMPILE_PREFIX%-}
if [ -z "$HOST_TRIPLE" ]; then
    echo "Warning: CROSS_COMPILE_PREFIX is empty, attempting native build configure."
    # For native builds, HOST_TRIPLE might not be needed, or configure guesses it.
else
    echo "Using HOST_TRIPLE: $HOST_TRIPLE"
fi

# Clean any previous configure/build artifacts first
# Although we rm -rf the dir, this is belt-and-suspenders for Autotools
if [ -f Makefile ]; then
    echo "Running make distclean..."
    make distclean || echo "make distclean failed (maybe not needed), continuing..."
fi

# Configure using Autotools standard procedure for cross-compilation
# Pass environment variables for compiler, flags, etc.
# Adding -D_GNU_SOURCE to CPPFLAGS and CFLAGS to help find definitions like makedev
echo "Running configure..."
# Note: --disable-xattr, --disable-shared, --enable-static are not valid options for this configure script.
# Set environment variables for configure
# IMPORTANT: Do not put comments on lines ending with a backslash (\)
CC="${CROSS_COMPILE_PREFIX}gcc" \
AR="${CROSS_COMPILE_PREFIX}ar" \
RANLIB="${CROSS_COMPILE_PREFIX}ranlib" \
STRIP="${CROSS_COMPILE_PREFIX}strip" \
CPPFLAGS="-D_GNU_SOURCE" \
CFLAGS="-D_GNU_SOURCE -O2 -Wall" \
LDFLAGS="-static" \
./configure \
    --host="$HOST_TRIPLE" \
    || { echo "Configure script failed!"; exit 1; }


# Run make to build the binary
echo "Running make..."
make V=1 # Add V=1 for verbose make output

echo "Build complete."

# --- Copy Output ---
# The final binary is typically in src/ after configure && make
BUILT_BINARY_PATH="${DIOD_SRC_DIR}/src/diod"
if [ ! -f "$BUILT_BINARY_PATH" ]; then
    echo "Error: Built diod binary not found at $BUILT_BINARY_PATH" >&2
    # Sometimes it might be in the top-level directory
    if [ -f "${DIOD_SRC_DIR}/diod" ]; then
        BUILT_BINARY_PATH="${DIOD_SRC_DIR}/diod"
        echo "Found binary at top level: ${BUILT_BINARY_PATH}"
    else
         echo "Also checked top-level directory. Build failed or binary location unknown." >&2
         exit 1
    fi
fi

echo "Copying built diod binary to $OUTPUT_BINARY_PATH"
cp "$BUILT_BINARY_PATH" "$OUTPUT_BINARY_PATH"
chmod +x "$OUTPUT_BINARY_PATH" # Ensure the final binary is executable

echo "build_9p.sh (diod with configure) finished successfully."
exit 0
