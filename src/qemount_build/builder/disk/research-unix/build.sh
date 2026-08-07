#!/bin/sh
set -eu

boot_iso=/host/build/bin/qemu/x86_64-9front/qemount/system/9front.iso
template=/host/build/data/templates/basic.tar

case "${RESEARCH_UNIX_FORMAT:?RESEARCH_UNIX_FORMAT is required}" in
    v6) reader=fs/v6fs ;;
    32v) reader=fs/32vfs ;;
    v10) reader=fs/v10fs ;;
    *)
        echo "Unsupported Research Unix format: $RESEARCH_UNIX_FORMAT" >&2
        exit 2
        ;;
esac

for output in "$@"; do
    output_path=/host/build/$output
    work=/work/research-unix

    rm -rf "$work"
    mkdir -p "$work/template" "$(dirname "$output_path")"
    tar -xf "$template" -C "$work/template"

    mkresearchunix.py "$RESEARCH_UNIX_FORMAT" "$output_path" "$work/template"

    printf '%s\n' "$reader" >"$work/reader"
    xorriso -as mkisofs -quiet -R \
        -graft-points \
        -o "$work/fixture.iso" \
        /reader="$work/reader" \
        /expected.txt="$work/template/basic/hello.txt" \
        /fixture.rc=/usr/local/share/qemount/research-unix/fixture.rc

    run-9front-fixture "$boot_iso" "$work/fixture.iso" "$output_path"
done
