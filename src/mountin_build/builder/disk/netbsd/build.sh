#!/bin/sh
set -e

# Loop over all outputs in META.provides
for output in $(echo "$META" | jq -r '.provides | keys[]'); do
    # Extract base name (strip path and extension)
    base_name=$(basename "$output" | sed 's/\.[^.]*$//')
    tar_path="/host/build/data/templates/${base_name}.tar"

    # Extract template to temp dir
    rm -rf /tmp/template
    mkdir -p /tmp/template
    tar -xf "$tar_path" -C /tmp/template

    # Create output directory and build filesystem
    output_path="/host/build/$output"
    mkdir -p "$(dirname "$output_path")"
    /build/buildfs.sh /tmp/template "$output_path"

    echo "Built: $output"
done
