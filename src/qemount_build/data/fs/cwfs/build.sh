#!/bin/sh
set -eu

boot_iso=/host/build/bin/qemu/x86_64-9front/qemount/9front.iso
template=/host/build/data/templates/basic.tar

for output in "$@"; do
    output_path=/host/build/$output
    work=/work/cwfs

    rm -rf "$work"
    mkdir -p "$work/template" "$(dirname "$output_path")"
    tar -xf "$template" -C "$work/template"
    xorriso -as mkisofs -quiet -R \
        -graft-points \
        -o "$work/fixture.iso" \
        /basic.tar="$template" \
        /expected.txt="$work/template/basic/hello.txt" \
        /fixture.rc=/build/fixture.rc

    truncate -s 64M "$output_path"
    run-9front-fixture "$boot_iso" "$work/fixture.iso" "$output_path"
done
