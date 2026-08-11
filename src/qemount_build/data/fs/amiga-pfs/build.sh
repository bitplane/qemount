#!/bin/sh
set -eu

BASE_ISO=/host/build/bin/qemu/i386-aros/system/aros.iso
TEMPLATE=/host/build/data/templates/basic.tar
POPULATE=/host/build/data/templates/basic.amiga

for output in "$@"; do
    output_path="/host/build/$output"
    work=/work/amiga-pfs
    template_dir="$work/template"
    disk="$work/pfs.rdb"
    format_iso="$work/format.iso"
    console_log="$work/console.log"

    rm -rf "$work"
    mkdir -p "$template_dir" "$(dirname "$output_path")"
    tar -xf "$TEMPLATE" -C "$template_dir"

    # Let amitools derive a valid geometry and assign all usable cylinders to
    # the single partition. Fixed cylinder numbers would make the fixture
    # depend on amitools' current geometry defaults.
    rdbtool -f "$disk" create size=32M \
        + init \
        + add dostype=PFS3

    # Format reads a literal carriage return before formatting, even in QUICK
    # mode. Supplying it as an ISO file keeps the build non-interactive.
    printf '\r' >"$work/format-confirm"
    xorriso \
        -indev "$BASE_ISO" \
        -outdev "$format_iso" \
        -boot_image any replay \
        -map "$template_dir" /TestData \
        -map "$work/format-confirm" /format-confirm \
        -map "$POPULATE" /populate \
        -map /build/grub.cfg /boot/grub/grub.cfg \
        -map /build/User-Startup /S/User-Startup \
        -commit

    if ! run-until-marker \
        "PFS3 fixture complete" \
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
        echo "AROS did not complete the PFS3 fixture"
        exit 1
    fi

    rdbtool -f "$disk" export 0 "$output_path"
    magic=$(od -An -tx1 -N4 "$output_path" | tr -d ' \n')
    if [ "$magic" != "50465301" ] && [ "$magic" != "50465302" ]; then
        cat "$work/qemu.log"
        cat "$console_log"
        echo "Expected a PFS boot block, found: $magic"
        exit 1
    fi
    if ! grep -Fq "Hello, world!" "$console_log" \
        || ! grep -Fq "This file is nested." "$console_log"
    then
        cat "$work/qemu.log"
        cat "$console_log"
        echo "AROS could not read the PFS test-data payload after flushing"
        exit 1
    fi

    echo "Built: $output"
done
