#!/bin/sh
set -eu

template=/host/build/data/templates/basic.tar
work=/tmp/adf-template

rm -rf "$work"
mkdir -p "$work"
tar -xf "$template" -C "$work"

for output in "$@"; do
    output_path="/host/build/$output"
    case "$(basename "$output")" in
        basic.ofs.adf)
            filesystem=ofs
            ;;
        basic.ffs.adf)
            filesystem=ffs
            ;;
        *)
            echo "Unknown ADF fixture: $output" >&2
            exit 1
            ;;
    esac

    mkdir -p "$(dirname "$output_path")"
    rm -f "$output_path"

    # xdftool selects standard 80x2x11 DD floppy geometry from the .adf
    # extension, producing a headerless 901,120-byte image.
    xdftool "$output_path" create \
        + format TestADF "$filesystem"

    (
        cd "$work"
        for item in *; do
            xdftool "$output_path" write "$item"
        done
    )

    size=$(stat -c %s "$output_path")
    if [ "$size" -ne 901120 ]; then
        echo "Expected an 880 KiB ADF, found $size bytes" >&2
        exit 1
    fi

    magic=$(od -An -tx1 -N4 "$output_path" | tr -d ' \n')
    case "$filesystem:$magic" in
        ofs:444f5300|ffs:444f5301)
            ;;
        *)
            echo "Unexpected $filesystem ADF boot-block magic: $magic" >&2
            exit 1
            ;;
    esac

    echo "Built: $output"
done
