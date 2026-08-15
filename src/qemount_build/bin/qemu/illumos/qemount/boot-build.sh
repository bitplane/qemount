#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

base=/opt/illumos/qemount
output=$base/boot/xplatform/i86pc/kernel/amd64/unix

mkdir -p "${output%/*}" /work
gcc -m32 -c /build/boot.S -o /work/boot.o
ld -m elf_i386 -Ttext=0xbff000 -e _start --oformat=binary \
    /work/boot.o -o /work/boot.bin
prefix_size=$((0xea8))
test "$(stat -c %s /work/boot.bin)" -le "$prefix_size"

dd if=/dev/zero of="$output.tmp" bs="$prefix_size" count=1 status=none
dd if=/work/boot.bin of="$output.tmp" conv=notrunc status=none
dd if="$base/kernel/unix" of="$output.tmp" bs=1M oflag=append \
    conv=notrunc status=none
mv "$output.tmp" "$output"
