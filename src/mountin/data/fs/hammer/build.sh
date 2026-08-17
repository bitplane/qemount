#!/bin/sh
set -eu

base_iso=/host/build/guest/x86_64-dragonfly/6.4.2/dragonfly.iso
template=/host/build/data/templates/basic.tar

for output in "$@"; do
    output_path=/host/build/$output
    work=/work/hammer
    template_dir=$work/template
    format_iso=$work/format.iso
    console_log=$work/console.log

    rm -rf "$work"
    mkdir -p "$template_dir" "$(dirname "$output_path")"
    tar -xf "$template" -C "$template_dir"
    truncate -s 1G "$output_path"

    xorriso \
        -indev "$base_iso" \
        -outdev "$format_iso" \
        -boot_image any replay \
        -map "$template_dir" /TestData \
        -map /build/fixture.rc /etc/mountin-fixture \
        -commit

    if ! run-until-marker \
        "HAMMER fixture complete" \
        "$console_log" \
        "$work/qemu.log" \
        120 \
        5 \
        -- \
        qemu-system-x86_64 \
            -machine q35 \
            -m 512 \
            -boot d \
            -cdrom "$format_iso" \
            -drive "file=$output_path,format=raw,if=virtio" \
            -display none \
            -serial "file:$console_log" \
            -monitor none \
            -no-reboot
    then
        cat "$work/qemu.log"
        cat "$console_log"
        echo "DragonFly did not complete the HAMMER fixture" >&2
        exit 1
    fi

    signature=$(od -An -tx1 -N8 "$output_path" | tr -d ' \n')
    if [ "$signature" != "313052c54d4d41c8" ]; then
        echo "Expected a HAMMER volume header, found: $signature" >&2
        exit 1
    fi

    echo "Built: $output"
done
