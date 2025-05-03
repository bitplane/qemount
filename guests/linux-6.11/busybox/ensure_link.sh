#!/bin/bash
set -euo pipefail

# Creates a symlink at LINK_PATH pointing to TARGET_PATH if it doesn't exist
LINK_PATH="$1"
TARGET_PATH="$2"

# Skip if link already exists
if [ -e "$LINK_PATH" ]; then
    echo "Link or file already exists at $LINK_PATH"
    exit 0
fi

# Ensure the directory for the link exists
mkdir -p "$(dirname "$LINK_PATH")"

# Get canonical paths 
LINK_DIR=$(dirname "$(readlink -f "$LINK_PATH")")
TARGET_ABSOLUTE=$(readlink -f "$TARGET_PATH")

# Create the symlink
echo "Creating link: $LINK_PATH -> $TARGET_PATH"
ln -sf "$TARGET_PATH" "$LINK_PATH"

exit 0