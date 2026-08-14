#!/bin/sh
set -eu

BASE_ISO=/host/build/bin/qemu/i386-aros/base/aros.iso
TEMPLATE=/host/build/data/templates/basic.tar
POPULATE=/host/build/data/templates/basic.amiga

for output in "$@"; do
    output_path="/host/build/$output"
    work=/work/amiga-sfs
    template_dir="$work/template"
    disk="$work/sfs.rdb"
    format_iso="$work/format.iso"
    console_log="$work/console.log"

    rm -rf "$work"
    mkdir -p "$template_dir" "$(dirname "$output_path")"
    tar -xf "$TEMPLATE" -C "$template_dir"

    # Use explicit geometry so the exported partition is cylinder-aligned and
    # can later be imported into composite RDB fixtures without truncation.
    rdbtool -f "$disk" create chs=4096,1,32 \
        + init \
        + add dostype=SFS0

    xorriso \
        -indev "$BASE_ISO" \
        -outdev "$format_iso" \
        -boot_image any replay \
        -map "$template_dir" /TestData \
        -map "$POPULATE" /populate \
        -map /build/grub.cfg /boot/grub/grub.cfg \
        -map /build/User-Startup /S/User-Startup \
        -commit

    if ! run-until-marker \
        "SFS fixture complete" \
        "$console_log" \
        "$work/qemu.log" \
        90 \
        5 \
        -- \
        qemu-system-x86_64 \
            -machine pc \
            -m 256 \
            -boot d \
            -cdrom "$format_iso" \
            -drive "file=$disk,format=raw,if=ide" \
            -display none \
            -serial "file:$console_log" \
            -monitor none \
            -no-reboot
    then
        cat "$work/qemu.log"
        cat "$console_log"
        echo "AROS did not complete the SFS fixture"
        exit 1
    fi

    rdbtool -f "$disk" export 0 "$output_path"
    magic=$(od -An -tx1 -N4 "$output_path" | tr -d ' \n')
    if [ "$magic" != "53465300" ]; then
        cat "$work/qemu.log"
        cat "$console_log"
        echo "Expected an SFS0 root block, found: $magic"
        exit 1
    fi
    if ! grep -Fq "Hello, world!" "$console_log" \
        || ! grep -Fq "This file is nested." "$console_log"
    then
        cat "$work/qemu.log"
        cat "$console_log"
        echo "AROS could not read the SFS test-data payload after flushing"
        exit 1
    fi

    echo "Built: $output"
done
