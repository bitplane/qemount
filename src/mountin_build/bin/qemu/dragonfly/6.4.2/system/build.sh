#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

WORLD=${DRAGONFLY_OBJ}/usr/src/world_x86_64
ROOT=/work/root
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_PLATFORM}/6.4.2/system
TARGET_INSTALL="${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin/install -N ${DRAGONFLY_SRC}/etc"

cd "$DRAGONFLY_SRC"

world_make()
{
    MAKEOBJDIRPREFIX="${DRAGONFLY_OBJ}/usr/src/world_x86_64" \
    OBJTREE="$DRAGONFLY_OBJ" \
    MACHINE_ARCH=x86_64 \
    MACHINE=x86_64 \
    MACHINE_PLATFORM=pc64 \
    LC_ALL=C \
    OBJFORMAT_PATH="${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64" \
    HOST_CCVER=gcc80 \
    CCVER=gcc80 \
    LDVER=ld.bfd \
    BINUTILSVER=binutils234 \
    WORLDBUILD=1 \
    DESTDIR="${DRAGONFLY_OBJ}/usr/src/world_x86_64" \
    _SHLIBDIRPREFIX="${DRAGONFLY_OBJ}/usr/src/world_x86_64" \
    INSTALL="$TARGET_INSTALL" \
    INSTALLSTRIPPED=1 \
    M4="${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin/m4" \
    PATH="${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/usr/sbin:${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/usr/bin:${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/sbin:${DRAGONFLY_OBJ}/usr/src/ctools_x86_64_x86_64/bin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/sbin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/usr/bin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/sbin:${DRAGONFLY_OBJ}/usr/src/btools_x86_64/bin:/usr/local/bin:/usr/pkg/bin" \
        /usr/bin/bmake -m "$DRAGONFLY_SRC/share/mk" -j"${JOBS}" \
            -DSYSBUILD -DNOMAN -DNOPIC -DNOPROFILE "$@"
}

top_make()
{
    HOST_CPU_FAMILY=${BUILD_PLATFORM%%-*}
    /usr/bin/bmake -j"${JOBS}" \
        BUILD_ARCH=x86_64 \
        HOST_CPU_FAMILY="$HOST_CPU_FAMILY" \
        HOST_CFLAGS="-D_GNU_SOURCE -DDRAGONFLY_LINUX_HOST -include /tmp/host-compat.h -I/usr/include/tirpc $(pkg-config --cflags libbsd-overlay)" \
        HOST_LDADD="/tmp/host-compat.o $(pkg-config --libs --static libbsd-overlay) -lresolv -ltirpc" \
        HOST_YACC=/usr/bin/byacc \
        MACHINE=x86_64 \
        MACHINE_ARCH=x86_64 \
        MACHINE_PLATFORM=pc64 \
        NOCLEAN=1 \
        NO_GAMES=1 \
        NO_SHARE=1 \
        TARGET_ARCH=x86_64 \
        TARGET_PLATFORM=pc64 \
        WORLD_VERSION=600401 \
        "$@"
}

top_make SUBDIR_OVERRIDE=stand _build-tools
top_make SUBDIR_OVERRIDE=stand _depend
top_make SUBDIR_OVERRIDE=stand everything
world_make -C "$DRAGONFLY_SRC/stand" install

world_make -C "$DRAGONFLY_SRC/libexec/rtld-elf" depend
world_make -C "$DRAGONFLY_SRC/libexec/rtld-elf" all
world_make -C "$DRAGONFLY_SRC/libexec/rtld-elf" install

while IFS= read -r path; do
    case "$path" in
        ""|\#*)
            ;;
        bin/*|sbin/*)
            world_make -C "$DRAGONFLY_SRC/$path" depend
            world_make -C "$DRAGONFLY_SRC/$path" all
            world_make -C "$DRAGONFLY_SRC/$path" install
            ;;
    esac
done < /build/runtime-files.txt

bmake -j"${JOBS}" \
    KERNCONF=MOUNTIN \
    MODULES_OVERRIDE="vfs/ext2fs vfs/ntfs vfs/udf libiconv" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    NOCLEAN=1 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    buildkernel

rm -rf "$ROOT"
mkdir -p "$ROOT"

bmake \
    DESTDIR="$WORLD" \
    KERNCONF=MOUNTIN \
    MODULES_OVERRIDE="vfs/ext2fs vfs/ntfs vfs/udf libiconv" \
    MACHINE=x86_64 \
    MACHINE_ARCH=x86_64 \
    MACHINE_PLATFORM=pc64 \
    TARGET_ARCH=x86_64 \
    TARGET_PLATFORM=pc64 \
    WORLD_VERSION=600401 \
    INSTALL="$TARGET_INSTALL" \
    INSTALLSTRIPPED=1 \
    reinstallkernel

/build/assemble-root.py "$WORLD" "$ROOT" /build/runtime-files.txt
mkdir -p "$ROOT/etc"
install -m 644 /build/loader.conf "$ROOT/boot/loader.conf"
install -m 644 /build/dloader.rc "$ROOT/boot/dloader.rc"
install -m 755 /build/mountin-rc "$ROOT/etc/rc"
install -m 644 "$DRAGONFLY_SRC/etc/login.conf" "$ROOT/etc/login.conf"
install -m 644 "$DRAGONFLY_SRC/initrd/etc/termcap" "$ROOT/etc/termcap"
mkdir -p "$ROOT/etc/defaults"
install -m 644 "$DRAGONFLY_SRC/etc/defaults/uuids" "$ROOT/etc/defaults/uuids"

for directory in dev mnt proc tmp var var/run; do
    mkdir -p "$ROOT/$directory"
done

for path in \
    boot/cdboot \
    boot/loader \
    boot/kernel/kernel \
    bin/sh \
    sbin/init \
    sbin/mount \
    sbin/mount_hammer \
    sbin/mount_hammer2 \
    sbin/newfs_hammer \
    sbin/newfs_hammer2 \
    sbin/umount
do
    test -e "$ROOT/$path"
done

mkdir -p "$OUTPUT_DIR"
xorriso -as mkisofs \
    -R \
    -J \
    -b boot/cdboot \
    -no-emul-boot \
    -V MOUNTIN_DRAGONFLY \
    -o "$OUTPUT_DIR/dragonfly.iso" \
    "$ROOT"

size=$(stat -c %s "$OUTPUT_DIR/dragonfly.iso")
limit=$((16 * 1024 * 1024))
if [ "$size" -gt "$limit" ]; then
    echo "DragonFly appliance exceeds 16 MiB: $size bytes" >&2
    exit 1
fi
