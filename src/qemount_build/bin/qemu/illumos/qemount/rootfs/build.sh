#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

base=/host/build/bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount
staging=/work/root
output=$base/rootfs.iso
source_archive=/host/build/sources/illumos-gate-linux-build.tar.gz

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
cp -a "$base/sysroot/lib/." "$staging/lib/"
# hsfs exposes the ABI aliases as symlinks, but the early runtime loader does
# not follow them while resolving indirect dependencies. Keep its default
# library directory concrete in the read-only appliance root.
rm "$staging/lib/64"
mkdir "$staging/lib/64"
cp -a "$base/sysroot/lib/amd64/." "$staging/lib/64/"
mkdir -p "$staging/usr/lib"
cp -a "$base/sysroot/usr/lib/." "$staging/usr/lib/"
install -m 0755 /host/build/bin/${OUTPUT_PLATFORM}/qemount-bootstrap \
    "$staging/sbin/init"
install -m 0755 /host/build/bin/${OUTPUT_PLATFORM}/qemount-init \
    "$staging/sbin/qemount-init"
install -m 0755 /host/build/bin/${OUTPUT_PLATFORM}/simple9p \
    "$staging/sbin/simple9p"
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
tar -xOf "$source_archive" --wildcards \
    '*/usr/src/uts/intel/os/name_to_sysnum' \
    > "$staging/etc/name_to_sysnum"

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
