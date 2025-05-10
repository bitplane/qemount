#!/bin/bash
set -euo pipefail

OUTPUT_FILE="$1"
SCRIPT_DIR="$(dirname "$0")"

mkdir -p "$(dirname "$OUTPUT_FILE")"
cp "$SCRIPT_DIR/run.sh" "$OUTPUT_FILE"
chmod +x "$OUTPUT_FILE"