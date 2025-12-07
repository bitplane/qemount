#!/bin/sh
echo "[SH] Shell mode"
echo "[SH] MOUNT_POINT=$MOUNT_POINT"
echo "[SH] MOUNT_SUCCESS=$MOUNT_SUCCESS"
echo ""

if [ "$MOUNT_SUCCESS" = "1" ]; then
    echo "Image mounted at $MOUNT_POINT"
    echo "Type 'ls $MOUNT_POINT' to explore"
else
    echo "No image mounted"
fi

echo ""
echo "Type 'exit' to shutdown"
echo ""

exec /bin/sh -i
