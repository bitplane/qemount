#!/bin/bash
set -euo pipefail

ARCH=$1
CONFIG_PATH=config/kernel/$ARCH/minimal.config

mkdir -p "$(dirname "$CONFIG_PATH")"

if [ -f "$CONFIG_PATH" ]; then
    echo "Kernel config already exists: $CONFIG_PATH"
    touch "$CONFIG_PATH"
    exit 0
fi

echo "Please create a kernel config manually at $CONFIG_PATH"
exit 1
