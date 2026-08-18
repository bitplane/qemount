#!/bin/sh
set -eu

test "$TARGET_ARCH" = x86_64

base=/opt/illumos/mountin
output=$base/boot/xplatform/i86pc/kernel/amd64/unix
kernel=$base/kernel/unix
wrapper_load_address=$((0xbff000))

dboot_image=$(nm -n "$kernel" \
    | awk '$3 == "dboot_image" { print "0x" $1; exit }')
dboot_image_address=$((dboot_image))
dboot_entry=$((dboot_image_address + 0x60))
set -- $(readelf -lW "$kernel" \
    | awk '$1 == "LOAD" { print $2, $4; exit }')
kernel_offset=$(( $1 ))
kernel_load_address=$(( $2 ))
prefix_size=$((kernel_load_address - wrapper_load_address - kernel_offset))

test -n "$dboot_image"
test "$prefix_size" -gt 0
test "$dboot_image_address" -eq "$kernel_load_address"

mkdir -p "${output%/*}" /work
gcc -m32 -DDBOOT_ENTRY="$dboot_entry" -c /build/boot.S -o /work/boot.o
ld -m elf_i386 -Ttext="$wrapper_load_address" -e _start --oformat=binary \
    /work/boot.o -o /work/boot.bin
test "$(stat -c %s /work/boot.bin)" -le "$prefix_size"

dd if=/dev/zero of="$output.tmp" bs="$prefix_size" count=1 status=none
dd if=/work/boot.bin of="$output.tmp" conv=notrunc status=none
dd if="$kernel" of="$output.tmp" bs=1M oflag=append \
    conv=notrunc status=none
mv "$output.tmp" "$output"
