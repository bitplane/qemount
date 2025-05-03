#!/bin/bash
#
# guest/linux-6.11/scripts/build_9p.sh
#
# Clones plan9port (if necessary) and builds 9pserve using its internal build system.
# It runs './INSTALL -b' within the source directory and copies the resulting binary.
# Assumes host build environment has git and standard build tools used by plan9port.
#
# Usage:
# ./guest/linux-6.11/scripts/build_9p.sh <TARGET_ARCH> <OUTPUT_BINARY_PATH> <CACHE_DIR>
#   - TARGET_ARCH: Architecture (e.g., x86_64, arm64). Used mainly for context.
#                  Cross-compilation requires setting environment variables *before* calling.
#   - OUTPUT_BINARY_PATH: The full path where the final static binary should be placed.
#   - CACHE_DIR: The full path to the shared cache directory.

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <TARGET_ARCH> <OUTPUT_BINARY_PATH> <CACHE_DIR>" >&2
    exit 1
fi

TARGET_ARCH="$1"
OUTPUT_BINARY_PATH="$2" # Expecting full path provided by Makefile
CACHE_DIR="$3"          # Expecting full path provided by Makefile

# --- Prerequisite Check ---
command -v git >/dev/null 2>&1 || { echo >&2 "Error: git command not found. Please install git."; exit 1; }
# Basic build tools are assumed to be present if plan9port's INSTALL script is expected to work
command -v file >/dev/null 2>&1 || { echo >&2 "Error: file command not found."; exit 1; }
command -v realpath >/dev/null 2>&1 || { echo >&2 "Error: realpath command not found."; exit 1; }


# --- Resolve Paths ---
OUTPUT_DIR=$(dirname "$OUTPUT_BINARY_PATH")
mkdir -p "$OUTPUT_DIR"
mkdir -p "$CACHE_DIR"

# --- Plan9Port Source Setup ---
P9P_SRC_DIR="$CACHE_DIR/plan9port"
P9P_REPO="https://github.com/9fans/plan9port.git"
# Expected location of the binary after ./INSTALL -b is run
EXPECTED_BINARY_REL="bin/9pserve"

# --- Clone Plan9Port (if needed) ---
if [ ! -d "$P9P_SRC_DIR/.git" ]; then
    echo "Cloning plan9port repository into $P9P_SRC_DIR..."
    git clone --depth 1 "$P9P_REPO" "$P9P_SRC_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone plan9port." >&2
        rm -rf "$P9P_SRC_DIR"
        exit 1
    fi
else
    echo "Using existing plan9port source directory: $P9P_SRC_DIR"
    # Optional: Update existing repo? Uncomment if desired.
    # echo "Updating plan9port repository..."
    # (cd "$P9P_SRC_DIR" && git pull) || echo "Warning: git pull failed, continuing with existing source."
fi

# --- Build using ./INSTALL -b ---
echo "Running './INSTALL -b' within $P9P_SRC_DIR..."
# NOTE: Assumes native compilation unless environment (CC, etc.) is pre-configured.
cd "$P9P_SRC_DIR"
# The '-b' flag is non-standard; relying on user expectation that it builds binaries.
if ! ./INSTALL -b; then
    echo "Error: './INSTALL -b' failed in $P9P_SRC_DIR." >&2
    echo "Check output above. Ensure build environment is correct and dependencies are met." >&2
    cd - > /dev/null # Go back even on failure
    exit 1
fi
cd - > /dev/null # Go back to original directory

# --- Locate the Built Binary ---
EXPECTED_BINARY_ABS=$(realpath "$P9P_SRC_DIR/$EXPECTED_BINARY_REL")
if [ ! -f "$EXPECTED_BINARY_ABS" ]; then
    echo "Error: Expected binary '$EXPECTED_BINARY_ABS' not found after running './INSTALL -b'." >&2
    echo "Check the output of the INSTALL script or the plan9port build system." >&2
    exit 1
fi
echo "Found binary: $EXPECTED_BINARY_ABS"

# --- Check Static Linkage ---
# Note: ./INSTALL might not produce a fully static binary by default.
echo "Checking static linkage of $EXPECTED_BINARY_ABS..."
LINKAGE_OUTPUT=$(file "$EXPECTED_BINARY_ABS")
if [[ "$LINKAGE_OUTPUT" != *"statically linked"* ]]; then
    echo "Warning: Built binary '$EXPECTED_BINARY_ABS' might not be fully statically linked!" >&2
    echo "file output: $LINKAGE_OUTPUT" >&2
    # Allow build to continue, but warn the user.
fi
echo "Binary static linkage check complete (using 'file' command)."

# --- Copy to Final Location ---
echo "Copying binary to $OUTPUT_BINARY_PATH"
# Use cp -f to overwrite existing file if necessary
cp -f "$EXPECTED_BINARY_ABS" "$OUTPUT_BINARY_PATH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy binary '$EXPECTED_BINARY_ABS' to '$OUTPUT_BINARY_PATH'." >&2
    exit 1
fi
# Ensure the copied binary is executable
chmod +x "$OUTPUT_BINARY_PATH"

echo "9pserve binary successfully built via './INSTALL -b' and placed at: $OUTPUT_BINARY_PATH"
exit 0
