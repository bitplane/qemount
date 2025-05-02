#!/bin/bash
set -euxo pipefail

ARCH=$1
DATA_DIR=$2
ISO_IMAGE=$3

ISO_DIR=$(dirname "$ISO_IMAGE")
mkdir -p "$ISO_DIR"

# Use dummy data if none provided
if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR"
  echo "Hello from afuse99p" > "$DATA_DIR/hello.txt"
fi

genisoimage -quiet -R -o "$ISO_IMAGE" "$DATA_DIR"
echo "ISO created at $ISO_IMAGE"
