#!/bin/sh
set -eu

boot_iso=/host/build/bin/qemu/x86_64-9front/qemount/system/9front.iso
template=/host/build/data/templates/basic.tar

for output in "$@"; do
    output_path=/host/build/$output
    work=/work/paqfs

    rm -rf "$work"
    mkdir -p "$work/template" "$(dirname "$output_path")"
    tar -xf "$template" -C "$work/template"

    xorriso -as mkisofs -quiet -R \
        -graft-points \
        -o "$work/fixture.iso" \
        /TestData="$work/template" \
        /fixture.rc=/build/fixture.rc

    truncate -s 16M "$work/output.fat"
    mkfs.vfat -F 16 -n QEMOUNTOUT "$work/output.fat"

    run-9front-fixture "$boot_iso" "$work/fixture.iso" "$work/output.fat"
    mcopy -i "$work/output.fat" ::/basic.paqfs "$output_path"

    signature=$(od -An -tx1 -N4 "$output_path" | tr -d ' \n')
    if [ "$signature" != "529ab12b" ]; then
        echo "Expected a PAQFS header, found: $signature" >&2
        exit 1
    fi
done

