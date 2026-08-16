#!/bin/sh
set -eu

base=/host/build/bin/qemu/x86_64-illumos/2026-08-13
rootfs=$base/rootfs.iso
output=/host/build/data/fs/basic.ufs-solaris

rm -rf /work/boot /work/fixture /work/root /work/rootfs.iso
mkdir -p /work/boot/xplatform/i86pc/kernel/amd64 /work/fixture /work/root
ln -s "$base/kernel" /work/boot/xplatform/i86pc/kernel/amd64/unix
tar -xf /host/build/data/templates/basic.tar -C /work/fixture

xorriso -osirrox on -indev "$rootfs" -extract / /work/root \
    >/work/xorriso.log 2>&1
cp -a /work/fixture /work/root/TestData
install -m 0755 /host/build/bin/x86_64-illumos/mkfs.ufs \
    /work/root/sbin/mkfs.ufs
install -m 0755 /host/build/bin/x86_64-illumos/ufs-fixture-init \
    /work/root/sbin/mountin-init
find /work/root -exec touch -h -d @0 {} +
xorriso -as mkisofs \
    -quiet \
    -graft-points \
    -d \
    -l \
    -r \
    -D \
    -J \
    -N \
    -relaxed-filenames \
    -o /work/rootfs.iso /work/root

truncate -s 32M "$output"
cd /work/boot
if ! run-until-marker \
    'illumos UFS fixture complete' \
    /work/serial.log /work/qemu.log 180 2 -- \
    qemu-system-x86_64 \
        -machine pc,accel=tcg \
        -m 512 \
        -smp 1 \
        -display none \
        -monitor none \
        -serial file:/work/serial.log \
        -no-reboot \
        -kernel xplatform/i86pc/kernel/amd64/unix \
        -initrd '/work/rootfs.iso type=rootfs' \
        -append '-B fstype=hsfs,console=ttya' \
        -drive file="$output",if=none,id=fixture,format=raw \
        -device virtio-blk-pci,drive=fixture; then
    cat /work/xorriso.log /work/qemu.log /work/serial.log >&2
    exit 1
fi

cat /work/serial.log
