#!/bin/sh
set -eu

root_partition=$(df / | awk 'NR == 2 { print $1 }')
root_device=${root_partition%s1}
target_device=
payload_device=

for device in /dev/disk[0-9]; do
    if [ "$device" = "$root_device" ]; then
        continue
    fi
    if [ -e "${device}s1" ]; then
        target_device=${device}s1
    else
        payload_device=$device
    fi
done

if [ -z "$target_device" ] || [ -z "$payload_device" ]; then
    echo "Could not identify target and payload disks" >&2
    exit 1
fi
target_raw_device=/dev/r${target_device#/dev/}

/sbin/newfs_hfs -J -v QEMOUNT "$target_raw_device"
mkdir -p /Volumes/QEMOUNT
/sbin/mount_hfs "$target_device" /Volumes/QEMOUNT
mkdir -p /Volumes/PAYLOAD
/sbin/mount_hfs -o rdonly "$payload_device" /Volumes/PAYLOAD

rm -rf /private/var/log/* /private/var/run/* /private/var/tmp/*

cd /
/bin/pax -rw -pe \
    APPLE_DRIVER_LICENSE.txt \
    APPLE_LICENSE.txt \
    Applications \
    bin \
    boot \
    cores \
    etc \
    Extra \
    Library \
    Network \
    private \
    sbin \
    System \
    tmp \
    usr \
    Users \
    var \
    /Volumes/QEMOUNT

mkdir -p /Volumes/QEMOUNT/dev /Volumes/QEMOUNT/Volumes
cp /Volumes/PAYLOAD/simple9p /Volumes/QEMOUNT/usr/bin/simple9p
cp /Volumes/PAYLOAD/stream64 /Volumes/QEMOUNT/usr/bin/stream64
cp /Volumes/PAYLOAD/kernel /Volumes/QEMOUNT/System/Library/Kernels/kernel
chmod 755 /Volumes/QEMOUNT/usr/bin/simple9p /Volumes/QEMOUNT/usr/bin/stream64
sync
/sbin/umount /Volumes/PAYLOAD
/sbin/umount /Volumes/QEMOUNT

printf 'QEMOUNT_%s\n' PROVISIONED
