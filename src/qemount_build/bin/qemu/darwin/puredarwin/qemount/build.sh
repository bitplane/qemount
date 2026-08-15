#!/bin/bash
set -euo pipefail

BASE_SYSTEM=/opt/puredarwin/base-system.tar.gz
BOOT_DIR=/opt/puredarwin/boot
SIMPLE9P=/host/build/bin/${OUTPUT_ARCH}-darwin/simple9p
STREAM64=/host/build/bin/${OUTPUT_ARCH}-darwin/stream64
QEMOUNT_INIT=/host/build/bin/${OUTPUT_ARCH}-darwin/qemount-init
KERNEL=/host/build/bin/qemu/${BUILD_ARCH}-linux/6.12/boot/kernel
ROOTFS=/host/build/bin/qemu/${BUILD_ARCH}-linux/6.12/boot/rootfs.img
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_PLATFORM}/17.4
OUTPUT=$OUTPUT_DIR/puredarwin.raw
STAGING=/work/root
SOURCE=/work/source.ext2
PARTITION=/work/root.hfsplus
DISK=/work/puredarwin.raw

source /build/qemu-linux-arch.sh
set_qemu_linux_arch_profile "$BUILD_ARCH"

rm -rf "$STAGING"
mkdir -p "$STAGING" "$OUTPUT_DIR"
rm -f "$SOURCE" "$PARTITION" "$DISK" "$OUTPUT.tmp"
tar -xzf "$BASE_SYSTEM" -C "$STAGING"

truncate -s "$PUREDARWIN_IMAGE_SIZE" "$DISK"
disk_bytes=$(stat -c %s "$DISK")
partition_offset=$((1024 * 1024))
if [ "$disk_bytes" -le "$partition_offset" ]; then
    echo "PureDarwin image must be larger than 1 MiB" >&2
    exit 1
fi
partition_bytes=$((disk_bytes - partition_offset))

rm -rf "$STAGING/usr/share/man" "$STAGING/usr/libexec/dtrace"
mkdir -p \
    "$STAGING/dev" \
    "$STAGING/Volumes/QEMOUNT_TARGET" \
    "$STAGING/private/tmp" \
    "$STAGING/private/var/db" \
    "$STAGING/private/var/log" \
    "$STAGING/private/var/root" \
    "$STAGING/private/var/run" \
    "$STAGING/private/var/tmp" \
    "$STAGING/boot/grub/i386-pc" \
    "$STAGING/sbin" \
    "$STAGING/usr/bin"
ln -s private/etc "$STAGING/etc"
ln -s private/tmp "$STAGING/tmp"
ln -s private/var "$STAGING/var"
install -m 755 "$SIMPLE9P" "$STAGING/usr/bin/simple9p"
install -m 755 "$STREAM64" "$STAGING/usr/bin/stream64"
install -m 755 "$QEMOUNT_INIT" "$STAGING/sbin/launchd"
install -m 644 "$BOOT_DIR/efiemu64.o" "$STAGING/boot/grub/i386-pc/efiemu64.o"

truncate -s "$partition_bytes" "$PARTITION"
mkfs.hfsplus -v QEMOUNT "$PARTITION"
root_uuid=$(blkid -s UUID -o value "$PARTITION")
if [ -z "$root_uuid" ]; then
    echo "Could not read the appliance HFS+ UUID" >&2
    exit 1
fi
cat > "$STAGING/boot/grub/grub.cfg" <<EOF
serial --unit=0 --speed=115200
terminal_output serial
echo Loading qemount PureDarwin
echo Loading EFI runtime
efiemu_loadcore /boot/grub/i386-pc/efiemu64.o
echo EFI runtime loaded
echo Loading XNU
xnu_kernel64 /System/Library/Kernels/kernel rd=uuid boot-uuid=$root_uuid -v serial=3 debug=0x8 -no-kext-autounload
echo Loading kernel extensions
xnu_kextdir /System/Library/Extensions
echo Starting XNU
boot
EOF

tree_size=$(du -sm "$STAGING" | cut -f1)
source_size=$((tree_size + 8))
truncate -s "${source_size}M" "$SOURCE"
mke2fs -q -t ext2 -d "$STAGING" "$SOURCE"

timeout 120 "$QEMU_BIN" \
    "${QEMU_MACHINE_ARGS[@]}" \
    -m 256 \
    -kernel "$KERNEL" \
    -drive "file=$ROOTFS,format=raw,if=virtio,readonly=on" \
    -drive "file=$SOURCE,format=raw,if=virtio,readonly=on" \
    -drive "file=$PARTITION,format=raw,if=virtio" \
    -append "root=/dev/vda ro console=$QEMU_CONSOLE mode=duplicate quiet" \
    -nographic \
    -no-reboot

printf '%s\n' \
    'label: dos' \
    'unit: sectors' \
    '' \
    'start=2048, type=af, bootable' \
    | sfdisk "$DISK"
dd if="$BOOT_DIR/boot.img" of="$DISK" bs=446 count=1 conv=notrunc status=none
dd if="$BOOT_DIR/core.img" of="$DISK" bs=512 seek=1 conv=notrunc status=none
dd if="$PARTITION" of="$DISK" bs=1M seek=1 conv=notrunc status=none

mv "$DISK" "$OUTPUT.tmp"
mv "$OUTPUT.tmp" "$OUTPUT"
