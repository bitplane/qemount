#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/aros-qemount-2026-07-30.tar.gz
CACHE_DIR=$QEMOUNT_CACHE_DIR
SOURCE_DIR=$CACHE_DIR/source
TOOLCHAIN_DIR=/opt/aros-toolchain
PORTS_DIR=/host/build/sources/aros-ports
GUEST_BUILD_DIR=$CACHE_DIR/toolchain-build
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-aros/system
SDK_OUTPUT=/host/build/lib/${OUTPUT_ARCH}-aros/sdk.tar.gz
ISO_OUTPUT=$OUTPUT_DIR/aros.iso
BUILD_JOBS=${JOBS:-1}

export CCACHE_DIR="$CACHE_DIR/ccache"
mkdir -p "$CACHE_DIR" "$CCACHE_DIR"

write_iso=false
write_sdk=false

if [ "$#" -eq 0 ]; then
    write_iso=true
    write_sdk=true
else
    for output in "$@"; do
        case "/host/build/$output" in
            "$ISO_OUTPUT")
                write_iso=true
                ;;
            "$SDK_OUTPUT")
                write_sdk=true
                ;;
            *)
                echo "Unknown AROS system output: $output" >&2
                exit 1
                ;;
        esac
    done
fi

# Port archives are produced by several upstream systems and can contain owner
# IDs that are not representable in a rootless container's user namespace.
# Archive ownership is irrelevant to the build, so apply the same policy to
# AROS's internal fetch helpers as to the source archive below.
TAR_OPTIONS=--no-same-owner
export TAR_OPTIONS

if [ ! -d "$SOURCE_DIR" ]; then
    temporary=$CACHE_DIR/source.tmp.$$
    rm -rf "$temporary"
    mkdir -p "$temporary"
    tar --no-same-owner -xzf "$SOURCE_ARCHIVE" \
        -C "$temporary" --strip-components=1
    mv "$temporary" "$SOURCE_DIR"
fi

if [ ! -f "$GUEST_BUILD_DIR/.qemount-bootstrap" ]; then
    rm -rf "$GUEST_BUILD_DIR"
    mkdir -p "$GUEST_BUILD_DIR"
    cp -a /opt/aros-bootstrap/. "$GUEST_BUILD_DIR/"
    touch "$GUEST_BUILD_DIR/.qemount-bootstrap"
fi
cd "$GUEST_BUILD_DIR"
"$SOURCE_DIR/configure" \
    --target="$AROS_TARGET" \
    --enable-target-variant="$AROS_VARIANT" \
    --enable-build-type=nightly \
    --enable-ccache \
    --with-portssources="$PORTS_DIR" \
    --with-aros-toolchain-install="$TOOLCHAIN_DIR" \
    --with-aros-toolchain=yes \
    --with-optimization="-Os -fno-defer-pop -mpreferred-stack-boundary=4" \
    --with-theme=AmigaOS3.x \
    --with-iconset=Mason \
    --with-bootloader=grub2

# Unlike the other fetched build inputs, AROS looks for pci.ids in its
# generated-file directory rather than PORTSSOURCEDIR.
PCI_IDS_DIR="$GUEST_BUILD_DIR/bin/${AROS_TARGET}-${AROS_VARIANT}/gen/rom/hidds/pci"
mkdir -p "$PCI_IDS_DIR"
cp "$PORTS_DIR/pci.ids" "$PCI_IDS_DIR/pci.ids"

# Build only the serial HIDD stubs needed by serial.device. AROS's aggregate
# libhiddstubs target collects every HIDD stub and, through the global linklibs
# target, expands this appliance build into the complete SDK.
HIDDSTUBS=$GUEST_BUILD_DIR/bin/${AROS_TARGET}-${AROS_VARIANT}/AROS/Developer/lib/libhiddstubs.a
make -j"$BUILD_JOBS" hidd-serial-stubs
mkdir -p "$(dirname "$HIDDSTUBS")"
/opt/aros-toolchain/i386-aros-ar rcs "$HIDDSTUBS" \
    "$GUEST_BUILD_DIR/bin/${AROS_TARGET}-${AROS_VARIANT}/gen/lib/hidd/serial_stubs.o"

while IFS= read -r target; do
    case "$target" in
        ""|\#*) continue ;;
    esac
    make -j"$BUILD_JOBS" "$target"
done < /build/mmake-targets.txt

AROS_DIR=$GUEST_BUILD_DIR/bin/${AROS_TARGET}-${AROS_VARIANT}/AROS
TARGET_ARCH=${AROS_TARGET%-*}
TARGET_CPU=${AROS_TARGET#*-}

while IFS= read -r line; do
    case "$line" in
        ""|\#*) continue ;;
    esac
    set -- $line
    current_dir=$1
    meta_target=$2
    shift 2
    goals=
    for path in "$@"; do
        goals="$goals $AROS_DIR/$path"
    done
    # Manifest paths cannot contain whitespace; splitting turns each selected
    # output into an independent make goal.
    # shellcheck disable=SC2086
    make --no-print-directory \
        TOP="$GUEST_BUILD_DIR" \
        SRCDIR="$SOURCE_DIR" \
        CURDIR="$current_dir" \
        TARGET="$meta_target" \
        AROS_HOST_ARCH=linux \
        AROS_HOST_CPU="$BUILD_ARCH" \
        AROS_TARGET_ARCH="$TARGET_ARCH" \
        AROS_TARGET_CPU="$TARGET_CPU" \
        --file="$GUEST_BUILD_DIR/$current_dir/mmakefile" \
        -j"$BUILD_JOBS" \
        $goals
done < /build/mmake-outputs.txt

if [ "$write_iso" = true ]; then
    STAGING_DIR=$CACHE_DIR/system-iso
    ISO_TMP=$ISO_OUTPUT.tmp

    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    while IFS= read -r path; do
        case "$path" in
            ""|\#*) continue ;;
        esac
        if [ ! -e "$AROS_DIR/$path" ]; then
            echo "Missing AROS appliance file: $path" >&2
            exit 1
        fi
        mkdir -p "$STAGING_DIR/$(dirname "$path")"
        cp -a "$AROS_DIR/$path" "$STAGING_DIR/$path"
    done < /build/system-files.txt

    mkdir -p \
        "$STAGING_DIR/boot/grub" \
        "$STAGING_DIR/Devs/DOSDrivers" \
        "$STAGING_DIR/S" \
        "$STAGING_DIR/T"
    cp -a "$AROS_DIR/boot/grub/i386-pc" "$STAGING_DIR/boot/grub/"
    cp "$SOURCE_DIR/workbench/devs/DOSDrivers/DEBUG" \
        "$STAGING_DIR/Devs/DOSDrivers/DEBUG"
    cp "$SOURCE_DIR/workbench/devs/DOSDrivers/SER" \
        "$STAGING_DIR/Devs/DOSDrivers/SER"
    cp "$SOURCE_DIR/workbench/fs/automount-config" \
        "$STAGING_DIR/L/automount-config"
    # dosboot uses this architecture marker to recognise the ISO as a system
    # volume. It is normally generated by AROS's distribution assembly.
    printf '%s\n' "$TARGET_CPU" >"$STAGING_DIR/AROS.boot"
    cp /build/grub.cfg "$STAGING_DIR/boot/grub/grub.cfg"
    cp /build/Startup-Sequence "$STAGING_DIR/S/Startup-Sequence"

    mkdir -p "$OUTPUT_DIR"
    rm -f "$ISO_TMP"
    mkisofs \
        -o "$ISO_TMP" \
        -b boot/grub/i386-pc/grub2_eltorito \
        -c boot/pc-tiny/boot.catalog \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -iso-level 4 \
        -V QEMOUNT_AROS_BASE \
        -publisher qemount \
        -sysid AROS-I386-PC \
        -l -J -r \
        "$STAGING_DIR"
    if [ "$(stat -c %s "$ISO_TMP")" -gt 16777216 ]; then
        echo "AROS system ISO exceeds the 16 MiB size budget" >&2
        exit 1
    fi
    mv "$ISO_TMP" "$ISO_OUTPUT"
fi

if [ "$write_sdk" = true ]; then
    mkdir -p "$(dirname "$SDK_OUTPUT")"
    tar -czf "$SDK_OUTPUT" \
        -C "$AROS_DIR" \
        Developer
fi
