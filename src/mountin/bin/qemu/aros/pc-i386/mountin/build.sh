#!/bin/sh
set -eu

BASE_ISO=/host/build/guest/${OUTPUT_ARCH}-aros/2026-07-30/aros.iso
NINED=/host/build/bin/${OUTPUT_ARCH}-aros/9d
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-aros/2026-07-30
OUTPUT_TMP=$OUTPUT_DIR/aros.iso.tmp
STAGING_DIR=/work/iso

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_TMP"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

extract_path() {
    path=$1
    mkdir -p "$STAGING_DIR/$(dirname "$path")"
    xorriso -osirrox on -indev "$BASE_ISO" \
        -extract "/$path" "$STAGING_DIR/$path"
}

while IFS= read -r path; do
    case "$path" in
        ""|\#*) continue ;;
    esac
    extract_path "$path"
done < /runtime-files.txt

GRUB_DIR=boot/grub/i386-pc
for file in \
    grub2_eltorito \
    core.img \
    command.lst \
    fs.lst \
    moddep.lst
do
    extract_path "$GRUB_DIR/$file"
done

extract_grub_module() {
    module=$1
    module_path=$GRUB_DIR/$module.mod
    if [ -f "$STAGING_DIR/$module_path" ]; then
        return
    fi
    extract_path "$module_path"
    dependencies=$(awk -F: -v module="$module" \
        '$1 == module { sub(/^[[:space:]]+/, "", $2); print $2 }' \
        "$STAGING_DIR/$GRUB_DIR/moddep.lst")
    for dependency in $dependencies; do
        extract_grub_module "$dependency"
    done
}

while IFS= read -r module; do
    case "$module" in
        ""|\#*) continue ;;
    esac
    extract_grub_module "$module"
done < /grub-modules.txt

mkdir -p "$STAGING_DIR/C" "$STAGING_DIR/S"
install -m 755 "$NINED" "$STAGING_DIR/C/9d"
install -m 644 /grub.cfg "$STAGING_DIR/boot/grub/grub.cfg"
install -m 644 /Startup-Sequence "$STAGING_DIR/S/Startup-Sequence"

xorriso -as mkisofs \
    -o "$OUTPUT_TMP" \
    -b boot/grub/i386-pc/grub2_eltorito \
    -c boot/pc-tiny/boot.catalog \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -iso-level 4 \
    -V "MOUNTIN_AROS" \
    -publisher "mountin" \
    -sysid "AROS-I386-PC" \
    -l -J -r \
    "$STAGING_DIR"
if [ "$(stat -c %s "$OUTPUT_TMP")" -gt 4194304 ]; then
    echo "AROS appliance ISO exceeds the 4 MiB size budget" >&2
    exit 1
fi
mv "$OUTPUT_TMP" "$OUTPUT_DIR/aros.iso"
