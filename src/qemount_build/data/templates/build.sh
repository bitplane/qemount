#!/bin/sh
set -e

OUTPUT_PATH="$1"

TEMPLATE_NAME=$(basename "$OUTPUT_PATH" .tar)

# Create tar from the corresponding directory
mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
tar -cf "/host/build/$OUTPUT_PATH" -C /build/ "$TEMPLATE_NAME"
