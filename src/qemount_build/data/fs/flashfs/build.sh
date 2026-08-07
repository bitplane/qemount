#!/bin/sh
set -eu

boot_iso=/host/build/bin/qemu/x86_64-9front/qemount/system/9front.iso
template=/host/build/data/templates/basic.tar

for output in "$@"; do
    output_path=/host/build/$output
    work=/work/flashfs

    rm -rf "$work"
    mkdir -p "$work" "$(dirname "$output_path")"

    xorriso -as mkisofs -quiet -R \
        -graft-points \
        -o "$work/fixture.iso" \
        /basic.tar="$template" \
        /fixture.rc=/build/fixture.rc

    truncate -s 2M "$output_path"
    run-9front-fixture "$boot_iso" "$work/fixture.iso" "$output_path"

    signature=$(od -An -tc -N4 "$output_path" | tr -d ' \n')
    if [ "$signature" != "ROO0" ]; then
        echo "Expected a FlashFS sector header, found: $signature" >&2
        exit 1
    fi
done
