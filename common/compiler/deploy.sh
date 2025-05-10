#!/bin/sh
# Default deployment script - copies output to host
if [ $# -eq 0 ]; then
    echo "Usage: deploy.sh <output-path>"
    exit 1
fi

OUTPUT_PATH="$1"
mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp -v "/outputs/$OUTPUT_PATH" "/host/build/$OUTPUT_PATH"