#!/bin/bash
# Usage: ./ensure_link.sh <link_path> <target_path>
# Creates a symlink at <link_path> pointing relatively to <target_path>
# if <link_path> does not already exist. Assumes target exists.

set -euo pipefail

LINK_PATH="$1"
TARGET_PATH="$2"

# Exit if link already exists (idempotent)
if [ -e "$LINK_PATH" ] || [ -L "$LINK_PATH" ]; then
    exit 0
fi

# Ensure the directory for the link exists
LINK_DIR=$(dirname "$LINK_PATH")
mkdir -p "$LINK_DIR"

# Create the relative symlink from LINK_PATH pointing to TARGET_PATH
# Use relative path calculation for robustness if paths change
TARGET_REL_PATH=$(realpath --relative-to="$LINK_DIR" "$TARGET_PATH")

echo "Creating link: $LINK_PATH -> $TARGET_REL_PATH"
ln -s "$TARGET_REL_PATH" "$LINK_PATH" || {
    echo "Error: Failed to create link $LINK_PATH -> $TARGET_REL_PATH" >&2
    exit 1
}

exit 0
