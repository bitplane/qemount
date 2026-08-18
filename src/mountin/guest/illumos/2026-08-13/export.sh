#!/bin/sh
set -eu

output=/host/build/guest/${MOUNTIN_TARGET_PLATFORM}/2026-08-13/system
temporary=${output}.tmp
mkdir -p "${output%/*}"
rm -rf "$temporary"
mkdir -p "$temporary"
root=$temporary/root
mkdir -p \
    "$root/dev" "$root/devices" "$root/etc/dfs" "$root/etc/svc/volatile" \
    "$root/kernel/amd64" "$root/lib" "$root/mnt" "$root/proc" "$root/sbin" \
    "$root/system/boot" "$root/system/contract" "$root/system/object" \
    "$root/platform/i86pc/kernel/amd64"
cp -a --no-preserve=ownership /build/root/. "$root/"
cp -a --no-preserve=ownership /opt/illumos/sysroot/lib/. "$root/lib/"
rm "$root/lib/64"
mkdir "$root/lib/64"
cp -a --no-preserve=ownership /opt/illumos/sysroot/lib/amd64/. "$root/lib/64/"
mkdir -p "$root/usr/lib"
cp -a --no-preserve=ownership /opt/illumos/sysroot/usr/lib/. "$root/usr/lib/"
ln -s ../devices/pseudo/cn@0:console "$root/dev/console"
ln -s ../devices/pseudo/mm@0:null "$root/dev/null"
ln -s ../devices/pseudo/mm@0:zero "$root/dev/zero"
ln -s ../devices/pseudo/sy@0:tty "$root/dev/tty"
printf '\n' > "$root/etc/dfs/sharetab"
printf '\n' > "$root/etc/mnttab"
cp -a --no-preserve=ownership /opt/illumos/mountin/modules/. "$root/"
install -m 0644 /opt/illumos/mountin/kernel/genunix "$root/kernel/amd64/genunix"
install -m 0644 /opt/illumos/mountin/kernel/unix \
    "$root/platform/i86pc/kernel/amd64/unix"
install -m 0644 /opt/illumos/share/name_to_sysnum "$root/etc/name_to_sysnum"
install -m 0644 /opt/illumos/mountin/boot/xplatform/i86pc/kernel/amd64/unix \
    "$temporary/kernel"
rm -rf "$output"
mv "$temporary" "$output"
