#!/bin/sh
set -eu

boot_iso=/host/build/bin/qemu/x86_64-9front/11957/9front.iso
template=/host/build/data/templates/basic.tar

for output in "$@"; do
    output_path=/host/build/$output
    work=/work/plan9-hjfs

    rm -rf "$work"
    mkdir -p "$work" "$(dirname "$output_path")"

    xorriso -as mkisofs -quiet -R \
        -graft-points \
        -o "$work/fixture.iso" \
        /basic.tar="$template" \
        /fixture.rc=/build/fixture.rc

    truncate -s 64M "$output_path"
    run-9front-fixture "$boot_iso" "$work/fixture.iso" "$output_path"
    python3 /build/verify.py "$output_path"
done
