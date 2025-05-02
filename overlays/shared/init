#!/bin/sh
set -eux

# Mount system filesystems
mount -t proc none /proc
mount -t sysfs none /sys

# Load ISO9660 if modular
modprobe isofs || insmod /lib/modules/*/kernel/fs/isofs/isofs.ko || echo "no isofs module"

# Mount the ISO image
mkdir -p /mnt
mount -t iso9660 /dev/sr0 /mnt || echo "Failed to mount ISO"

# Export it via 9p back to host using shared mountpoint
mkdir -p /host
mount -t 9p -o trans=virtio,version=9p2000.L fusekfs /host || echo "Failed to mount host 9p"

# Mirror the ISO into host-visible dir
mkdir -p /host/mnt
cp -a /mnt/* /host/mnt/ || echo "Failed to export ISO to host"

# Block forever until umount on host
echo "Boot complete. Waiting..."
exec tail -f /dev/null
