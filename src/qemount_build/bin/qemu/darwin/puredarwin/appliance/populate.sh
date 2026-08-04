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

cd /
while IFS= read -r path; do
    case "$path" in
        ''|'#'*) continue ;;
    esac
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        echo "Missing appliance path: $path" >&2
        exit 1
    fi
    /bin/pax -rw -pe "$path" /Volumes/QEMOUNT
done < /Volumes/PAYLOAD/appliance.manifest

mkdir -p \
    /Volumes/QEMOUNT/dev \
    /Volumes/QEMOUNT/Volumes \
    /Volumes/QEMOUNT/Volumes/QEMOUNT_TARGET \
    /Volumes/QEMOUNT/private/tmp \
    /Volumes/QEMOUNT/private/var/db \
    /Volumes/QEMOUNT/private/var/log \
    /Volumes/QEMOUNT/private/var/root \
    /Volumes/QEMOUNT/private/var/run \
    /Volumes/QEMOUNT/private/var/tmp \
    /Volumes/QEMOUNT/sbin \
    /Volumes/QEMOUNT/usr/bin
cp /Volumes/PAYLOAD/simple9p /Volumes/QEMOUNT/usr/bin/simple9p
cp /Volumes/PAYLOAD/stream64 /Volumes/QEMOUNT/usr/bin/stream64
cp /Volumes/PAYLOAD/qemount-init /Volumes/QEMOUNT/sbin/launchd
chmod 755 /Volumes/QEMOUNT/usr/bin/simple9p /Volumes/QEMOUNT/usr/bin/stream64
chmod 755 /Volumes/QEMOUNT/sbin/launchd
sync
/sbin/umount /Volumes/PAYLOAD
/sbin/umount /Volumes/QEMOUNT

printf 'QEMOUNT_%s\n' PROVISIONED
