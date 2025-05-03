#!/bin/sh
set -eux
TARGET_DEV=${mountq_target:-/dev/vda}
FALLBACK_DEV=${mountq_fallback:-/dev/sr0}
MOUNT_POINT=/mnt
PORT_PATH=/dev/virtio-ports/org.qemu.9p.export

mount -t devtmpfs devtmpfs /dev
mount -t proc none /proc
mount -t sysfs none /sys
mkdir -p "$MOUNT_POINT"

# Try to detect available device
if [ -b "$TARGET_DEV" ]; then
  DEVICE_TO_MOUNT="$TARGET_DEV"
elif [ -b "$FALLBACK_DEV" ]; then
  DEVICE_TO_MOUNT="$FALLBACK_DEV"
else
  echo "Error: Neither $TARGET_DEV nor $FALLBACK_DEV block device found!"
  DEVICE_TO_MOUNT=""
fi

# Attempt to mount
if [ -n "$DEVICE_TO_MOUNT" ]; then
  if mount -t auto "$DEVICE_TO_MOUNT" "$MOUNT_POINT"; then
    MOUNT_SUCCESS=1
  else
    echo "Failed to mount $DEVICE_TO_MOUNT automatically"
    MOUNT_SUCCESS=0
  fi
else
  echo "No target device found to mount."
  MOUNT_SUCCESS=0
fi
# Start 9P server if mount succeeded
if [ "$MOUNT_SUCCESS" -eq 1 ]; then
  if [ -e "$PORT_PATH" ]; then
    echo "[INFO] Starting 9P server..."
    9pserve "$PORT_PATH" "$MOUNT_POINT" &
  else
    echo "[ERROR] 9P port path not found: $PORT_PATH"
  fi
else
  echo "[WARN] Skipping 9P server startup due to failed mount."
fi

# Run interactive shell (blocking, not backgrounded)
/bin/sh 

# Shut down the VM afterwards, or sleep forever
# (important because it'll spin lock otherwise)
poweroff -f || sleep infinity
