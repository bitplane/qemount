#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

base=/opt/illumos/mountin
staging=/work/root
output_base=/host/build/bin/qemu/${OUTPUT_PLATFORM}/2026-08-13
output=$output_base/rootfs.iso

rm -rf "$staging"
mkdir -p \
    "$staging/dev" \
    "$staging/devices" \
    "$staging/etc/dfs" \
    "$staging/etc/svc/volatile" \
    "$staging/kernel/amd64" \
    "$staging/lib" \
    "$staging/mnt" \
    "$staging/platform/i86pc/kernel/amd64" \
    "$staging/proc" \
    "$staging/sbin" \
    "$staging/system/boot" \
    "$staging/system/contract" \
    "$staging/system/object"
cp -a /build/root/. "$staging/"
cp -a /opt/illumos/sysroot/lib/. "$staging/lib/"
# hsfs exposes the ABI aliases as symlinks, but the early runtime loader does
# not follow them while resolving indirect dependencies. Keep its default
# library directory concrete in the read-only appliance root.
rm "$staging/lib/64"
mkdir "$staging/lib/64"
cp -a /opt/illumos/sysroot/lib/amd64/. "$staging/lib/64/"
mkdir -p "$staging/usr/lib"
cp -a /opt/illumos/sysroot/usr/lib/. "$staging/usr/lib/"
install -m 0755 /host/build/bin/${OUTPUT_PLATFORM}/mountin-bootstrap \
    "$staging/sbin/init"
install -m 0755 /host/build/bin/${OUTPUT_PLATFORM}/mountin-init \
    "$staging/sbin/mountin-init"
install -m 0755 /host/build/bin/${OUTPUT_PLATFORM}/9d \
    "$staging/sbin/9d"
ln -s ../devices/pseudo/cn@0:console "$staging/dev/console"
ln -s ../devices/pseudo/mm@0:null "$staging/dev/null"
ln -s ../devices/pseudo/mm@0:zero "$staging/dev/zero"
ln -s ../devices/pseudo/sy@0:tty "$staging/dev/tty"
printf '\n' > "$staging/etc/dfs/sharetab"
printf '\n' > "$staging/etc/mnttab"
cp -a "$base/modules/." "$staging/"
install -m 0644 "$base/kernel/genunix" "$staging/kernel/amd64/genunix"
install -m 0644 "$base/kernel/unix" \
    "$staging/platform/i86pc/kernel/amd64/unix"
install -m 0644 /opt/illumos/share/name_to_sysnum \
    "$staging/etc/name_to_sysnum"

mkdir -p "${output%/*}"
find "$staging" -exec touch -h -d @0 {} +
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
    -o "$output.tmp" "$staging"
mv "$output.tmp" "$output"

kernel=$output_base/kernel
mkdir -p "${kernel%/*}"
install -m 0644 \
    "$base/boot/xplatform/i86pc/kernel/amd64/unix" "$kernel"
