#!/bin/sh
set -eu

ROOT=$1
KERNEL_DIR=$ROOT/boot/kernel

# installworld includes a complete native development environment. qemount
# builds on the host, so none of it belongs in the runtime appliance.
rm -rf \
    "$ROOT/build" \
    "$ROOT/usr/include" \
    "$ROOT/usr/libexec/binutils227" \
    "$ROOT/usr/libexec/binutils234" \
    "$ROOT/usr/libexec/gcc47" \
    "$ROOT/usr/libexec/gcc80" \
    "$ROOT/usr/libdata" \
    "$ROOT/usr/lib/gcc47" \
    "$ROOT/usr/lib/gcc80" \
    "$ROOT/usr/share"

find "$ROOT/usr/lib" -type f \
    \( -name '*.a' -o -name '*.la' -o -name '*.o' \) -delete

# Debuggers, source-control clients and build tools are installed as part of
# world, but the appliance never compiles or inspects binaries in the guest.
rm -f \
    "$ROOT/usr/bin/CC" \
    "$ROOT/usr/bin/addr2line" \
    "$ROOT/usr/bin/ar" \
    "$ROOT/usr/bin/as" \
    "$ROOT/usr/bin/byacc" \
    "$ROOT/usr/bin/c++" \
    "$ROOT/usr/bin/c++filt" \
    "$ROOT/usr/bin/cc" \
    "$ROOT/usr/bin/ci" \
    "$ROOT/usr/bin/co" \
    "$ROOT/usr/bin/cpp" \
    "$ROOT/usr/bin/cvs" \
    "$ROOT/usr/bin/elfedit" \
    "$ROOT/usr/bin/flex" \
    "$ROOT/usr/bin/flex++" \
    "$ROOT/usr/bin/g++" \
    "$ROOT/usr/bin/gdb" \
    "$ROOT/usr/bin/gcc" \
    "$ROOT/usr/bin/gcov" \
    "$ROOT/usr/bin/gprof" \
    "$ROOT/usr/bin/kgdb" \
    "$ROOT/usr/bin/ld" \
    "$ROOT/usr/bin/ld.bfd" \
    "$ROOT/usr/bin/ld.gold" \
    "$ROOT/usr/bin/lex" \
    "$ROOT/usr/bin/lex++" \
    "$ROOT/usr/bin/make" \
    "$ROOT/usr/bin/nm" \
    "$ROOT/usr/bin/objcopy" \
    "$ROOT/usr/bin/objdump" \
    "$ROOT/usr/bin/objformat" \
    "$ROOT/usr/bin/ranlib" \
    "$ROOT/usr/bin/rcs" \
    "$ROOT/usr/bin/rcsclean" \
    "$ROOT/usr/bin/rcsdiff" \
    "$ROOT/usr/bin/rcsmerge" \
    "$ROOT/usr/bin/readelf" \
    "$ROOT/usr/bin/rlog" \
    "$ROOT/usr/bin/size" \
    "$ROOT/usr/bin/strings" \
    "$ROOT/usr/bin/strip" \
    "$ROOT/usr/bin/yacc" \
    "$ROOT/usr/sbin/acpiexec" \
    "$ROOT/usr/sbin/acpihelp" \
    "$ROOT/usr/sbin/iasl" \
    "$ROOT/usr/sbin/makefs"

# The generic kernel contains the QEMU storage devices and DragonFly's native
# filesystems. Keep only the modules which add tested filesystem support.
for module in \
    ext2fs.ko \
    libiconv.ko \
    ntfs.ko \
    ntfs_iconv.ko \
    udf.ko
do
    test -f "$KERNEL_DIR/$module"
done

find "$KERNEL_DIR" -mindepth 1 -maxdepth 1 -type f \
    ! -name kernel \
    ! -name ext2fs.ko \
    ! -name libiconv.ko \
    ! -name ntfs.ko \
    ! -name ntfs_iconv.ko \
    ! -name udf.ko \
    -delete

# nrelease presentation files are useful on an installation CD, not in a
# serial filesystem appliance.
rm -rf "$ROOT/autorun"
rm -f \
    "$ROOT/README" \
    "$ROOT/README.USB" \
    "$ROOT/autorun.bat" \
    "$ROOT/autorun.inf" \
    "$ROOT/autorun.pif" \
    "$ROOT/cpignore" \
    "$ROOT/dflybsd.ico" \
    "$ROOT/index.html"

# Fail here rather than publish an image which cannot exercise the two native
# filesystems used by the test-data builders.
for path in \
    bin/cat \
    bin/cp \
    bin/mkdir \
    bin/sh \
    sbin/init \
    sbin/mount \
    sbin/mount_hammer \
    sbin/mount_hammer2 \
    sbin/newfs_hammer \
    sbin/newfs_hammer2 \
    sbin/shutdown \
    sbin/umount
do
    test -e "$ROOT/$path"
done
