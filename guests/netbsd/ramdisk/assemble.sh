#!/bin/sh
# Assemble NetBSD ramdisk with rescue binaries and additional tools
set -eu

OUTPUT_PATH="$1"
ARCH="${ARCH:-x86_64}"

NBARCH=$(cat /tmp/nbarch)

echo "Building NetBSD ramdisk for $ARCH..."

# Build ramdisk directory structure with rescue binaries
/tmp/build-ramdisk.sh /usr/obj/destdir.$NBARCH /ramdisk

# Copy init scripts and etc files from root overlay
cp -v /build/root/sbin/init /ramdisk/sbin/init
chmod 755 /ramdisk/sbin/init
cp -v /build/root/init.sh /ramdisk/init.sh
chmod 755 /ramdisk/init.sh
cp -v /build/root/init.9p /ramdisk/init.9p
chmod 755 /ramdisk/init.9p
cp -v /build/root/etc/* /ramdisk/etc/

# Copy additional binaries from host build
if [ -f /host/build/guests/netbsd/rootfs/${ARCH}/bin/simple9p ]; then
    echo "Adding simple9p to ramdisk..."
    cp -v /host/build/guests/netbsd/rootfs/${ARCH}/bin/simple9p /ramdisk/bin/simple9p
    chmod 755 /ramdisk/bin/simple9p
fi

if [ -f /host/build/guests/netbsd/rootfs/${ARCH}/bin/socat ]; then
    echo "Adding socat to ramdisk..."
    cp -v /host/build/guests/netbsd/rootfs/${ARCH}/bin/socat /ramdisk/bin/socat
    chmod 755 /ramdisk/bin/socat
fi

# Show ramdisk contents
echo "Ramdisk contents:"
ls -la /ramdisk/bin/ /ramdisk/sbin/ || true

# Create ramdisk filesystem image (16MB for rescue binary + extras)
# Use FFS v1 for compatibility with memory disk boot
/usr/tools/bin/nbmakefs -s 16m -t ffs -o version=1 /ramdisk.fs /ramdisk

# Copy to outputs
mkdir -p /outputs/guests/netbsd/ramdisk/${ARCH}
cp /ramdisk.fs /outputs/guests/netbsd/ramdisk/${ARCH}/ramdisk.fs

echo "Done! Ramdisk: /outputs/guests/netbsd/ramdisk/${ARCH}/ramdisk.fs"

# Deploy using standard script
/usr/local/bin/deploy.sh guests/netbsd/ramdisk/${ARCH}/ramdisk.fs
