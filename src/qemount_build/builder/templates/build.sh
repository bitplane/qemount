#!/bin/sh
set -e

# Create tars for all template directories
for dir in /templates/*/; do
    name=$(basename "$dir")
    output="/host/build/data/templates/${name}.tar"
    mkdir -p "$(dirname "$output")"
    echo "Creating $output"
    tar -cf "$output" -C /templates/ "$name"
done
