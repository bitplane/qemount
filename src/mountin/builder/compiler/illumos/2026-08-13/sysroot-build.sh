#!/bin/sh
set -eu

test "$TARGET_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
makefile=$src/cmd/make/bin/make.rules.file
output=/opt/illumos/sysroot

export LD_LIBRARY_PATH=/opt/schily/lib

run_make()
{
    cd "$1"
    shift
    dmake -r -f "$makefile" -f Makefile \
        "MAKE=dmake -r -f $makefile -f Makefile" \
        SRC="$src" CODEMGR_WS=/source \
        MACH=i386 MACH64=amd64 NATIVE_MACH=amd64 NATIVE_MACH64=amd64 \
        RELEASE_BUILD= NATIVE_OS=linux \
        GNU_ROOT=/opt/illumos-binutils \
        GNUC_ROOT=/usr NATIVE_GNUC_ROOT=/usr \
        ONBLD_TOOLS="$onbld" \
        ROOT=/proto \
        ENVCPPFLAGS1=-I/proto/usr/include \
        ENVLDLIBS1=-L/proto/lib \
        ENVLDLIBS2=-L/proto/usr/lib \
        "$@"
}

rm -rf "$output"
mkdir -p "$output/lib/amd64" "$output/usr/lib/amd64"

run_make "$src/uts/common/sys" all_h
run_make "$src/uts/common/rpc" all_h
run_make "$src/uts/common/rpcsvc" all_h
run_make "$src" rootdirs
run_make "$src/head" install_h
run_make "$src/uts/common/sys" install_h
run_make "$src/uts/common/rpc" install_h
run_make "$src/uts/common/rpcsvc" install_h
run_make "$src/uts/common/gssapi" install_h
run_make "$src/uts/common/nfs" install_h
run_make "$src/uts/common/sharefs" install_h
run_make "$src/uts/common/vm" install_h
run_make "$src/uts/common/net" install_h
run_make "$src/uts/common/netinet" install_h
run_make "$src/uts/common/c2" install_h
run_make "$src/uts/intel/sys" install_h
run_make "$src/lib/libnvpair" install_h
run_make "$src/lib/libmd" install_h
run_make "$src/lib/libscf" install_h
run_make "$src/lib/libtsol" install_h
run_make "$src/lib/libdemangle" install_h
run_make "$src/lib/libc" /proto/usr/include/getxby_door.h
test -r /proto/usr/include/sys/feature_tests.h
test -r /proto/usr/include/sys/asm_linkage.h
/usr/bin/gcc -m64 -fpic -g -gdwarf-4 -c /build/plockstat-stubs.c \
    -o /build/plockstat-stubs.o
"$onbld/bin/i386/ctfconvert" -L VERSION /build/plockstat-stubs.o
run_make "$src/lib/libc/amd64" libc.so.1 \
    ALTPICS=/build/plockstat-stubs.o \
    CTFMERGE=/usr/bin/true
run_make "$src/lib/libc/amd64" libc_pic.a \
    CTFMERGE=/usr/bin/true
run_make "$src/lib/ssp_ns/amd64" all
run_make "$src/lib/crt/amd64" install

mkdir -p /proto/lib/amd64 /proto/usr/lib/amd64
install -m 0755 "$src/lib/libc/amd64/libc.so.1" \
    /proto/lib/amd64/libc.so.1
ln -s libc.so.1 /proto/lib/amd64/libc.so
install -m 0644 "$src/lib/ssp_ns/amd64/libssp_ns.a" \
    /proto/usr/lib/amd64/libssp_ns.a

run_make "$src/cmd/sgs/libconv/amd64" all \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/libelf/amd64" install \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/liblddbg/amd64" all \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/librtld/amd64" all \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/libld/amd64" all \
    CTFMERGE=/usr/bin/true

run_make "$src/cmd/sgs/rtld/amd64" all \
    CUSERFLAGS64=-_gcc=-fno-omit-frame-pointer \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/liblddbg/amd64" install \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/librtld/amd64" install \
    CTFMERGE=/usr/bin/true
run_make "$src/cmd/sgs/libld/amd64" install \
    CTFMERGE=/usr/bin/true

cp -a /proto/lib/amd64/. "$output/lib/amd64/"
cp -a /proto/usr/include "$output/usr/"
cp -a /proto/usr/lib/amd64/. "$output/usr/lib/amd64/"
install -m 0755 "$src/cmd/sgs/rtld/amd64/ld.so.1" \
    "$output/lib/amd64/ld.so.1"
ln -s amd64 "$output/lib/64"
ln -s amd64 "$output/usr/lib/64"

mkdir -p /opt/illumos/share
install -m 0644 "$src/uts/intel/os/name_to_sysnum" \
    /opt/illumos/share/name_to_sysnum
