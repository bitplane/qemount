#!/bin/bash
set -eux

ARCH=$1
DATA_DIR=$2
ISO_IMAGE=$3

mkdir -p "$(dirname "$ISO_IMAGE")"

# Use dummy data if none provided
if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR"
  echo "Hello from afuse99p" > "$DATA_DIR/hello.txt"
fi

genisoimage -quiet -o "$ISO_IMAGE" -R "$DATA_DIR"
echo "ISO created at $ISO_IMAGE"
