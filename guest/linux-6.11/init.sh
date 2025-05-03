#!/bin/sh
set -eux # Exit on error, print commands

# Filesystem types to attempt mounting with (prioritize common ones)
# List based on kernel config aiming for built-in support
FS_TYPES="ext4 ext3 ext2 iso9660 udf vfat exfat ntfs3 ntfs btrfs xfs f2fs squashfs hfsplus hfs jfs reiserfs minix msdos ufs sysv affs adfs befs bfs efs cramfs hpfs qnx4 qnx6 romfs nilfs2 omfs vxfs gfs2 bcachefs"

# Target device (passed via virtio-blk in run.sh.template)
TARGET_DEV="/dev/vda"
# Fallback device (e.g., if passed via -cdrom)
FALLBACK_DEV="/dev/sr0"

# Mount point for the target filesystem
MOUNT_POINT="/mnt"

# Mount essential virtual filesystems
echo "Mounting virtual filesystems..."
mount -t proc none /proc
mount -t sysfs none /sys
# Assuming kernel has CONFIG_DEVTMPFS=y and CONFIG_DEVTMPFS_MOUNT=y
# If /dev is empty, uncomment: mount -t devtmpfs none /dev

# Create mount point for the target image
mkdir -p "$MOUNT_POINT"

# Determine which device actually exists
if [ -b "$TARGET_DEV" ]; then
    DEVICE_TO_MOUNT="$TARGET_DEV"
    echo "Found target device: $DEVICE_TO_MOUNT"
elif [ -b "$FALLBACK_DEV" ]; then
    DEVICE_TO_MOUNT="$FALLBACK_DEV"
    echo "Found fallback device: $DEVICE_TO_MOUNT"
else
    echo "Error: Neither $TARGET_DEV nor $FALLBACK_DEV block device found!"
    DEVICE_TO_MOUNT=""
fi

# Attempt to mount the device with different filesystem types
MOUNT_SUCCESS=0
SUCCESS_FS_TYPE=""
if [ -n "$DEVICE_TO_MOUNT" ]; then
    echo "Attempting to mount $DEVICE_TO_MOUNT on $MOUNT_POINT..."
    for fs_type in $FS_TYPES; do
        echo "Trying filesystem type: $fs_type"
        # Try mounting read-only first for safety and compatibility
        # Ignore errors temporarily within the loop
        if mount -t "$fs_type" -o ro "$DEVICE_TO_MOUNT" "$MOUNT_POINT" 2>/dev/null; then
            echo "Successfully mounted $DEVICE_TO_MOUNT as $fs_type (read-only)"
            MOUNT_SUCCESS=1
            SUCCESS_FS_TYPE="$fs_type"
            break # Exit loop on first success
        fi
        # Add a small delay if mount attempts are extremely rapid and causing issues (unlikely)
        # sleep 0.05
    done

    if [ "$MOUNT_SUCCESS" -eq 0 ]; then
        echo "Failed to mount $DEVICE_TO_MOUNT with any known filesystem type."
    fi
else
    echo "No target device found to mount."
fi

# --- 9P Export ---
# Create host mount point directory within the initramfs
mkdir -p /host

# Attempt to mount 9P export from host
# Assumes kernel has CONFIG_NET_9P=y, CONFIG_NET_9P_VIRTIO=y, CONFIG_9P_FS=y
echo "Attempting to mount host via 9p..."
# Use options from run.sh.template: trans=virtio, version=9p2000.L
# Add msize for potentially better performance
if mount -t 9p -o trans=virtio,version=9p2000.L,msize=131072 fusekfs /host; then
    echo "Successfully mounted host 9p filesystem on /host"
    HOST_MOUNT_SUCCESS=1
else
    ret=$?
    echo "Failed to mount host 9p (fusekfs) with error $ret. Check kernel 9P config."
    HOST_MOUNT_SUCCESS=0
fi

# --- Copy Data (if both mounts succeeded) ---
if [ "$MOUNT_SUCCESS" -eq 1 ] && [ "$HOST_MOUNT_SUCCESS" -eq 1 ]; then
    echo "Copying contents of $MOUNT_POINT ($SUCCESS_FS_TYPE) to /host/mnt..."
    # Ensure target directory exists on host share
    mkdir -p /host/mnt
    # Copy contents recursively. Use -r for broader compatibility than -a.
    # Ignore errors during copy (e.g., permission issues on source FS)
    cp -r "$MOUNT_POINT"/* /host/mnt/ 2>/dev/null || echo "Warning: Errors occurred during copy to host via 9p. Copy may be incomplete."
    echo "Copy complete (or attempted)."
    # Optional: Sync filesystem buffers to ensure data is sent over 9p
    echo "Syncing filesystems..."
    sync
    # Optional: Unmount the host share cleanly before poweroff
    echo "Unmounting host share..."
    umount /host || echo "Warning: Failed to unmount /host"
else
    echo "Skipping copy to host: Either guest mount or host 9p mount failed."
fi

# --- Final Shutdown ---
echo "Setup complete. Requesting power off..."
# Use poweroff -f to force shutdown without trying to kill processes/sync disks again
# This should signal QEMU via ACPI (if enabled in kernel) to exit.
poweroff -f

# Fallback in case poweroff fails (should not be reached if ACPI works)
echo "Poweroff command failed? Halting."
halt -p -f

# Ultimate fallback
echo "Halting failed? Entering infinite sleep."
while true; do sleep 3600; done

