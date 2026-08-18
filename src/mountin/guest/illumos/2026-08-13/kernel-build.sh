#!/bin/sh
set -eu

test "$MOUNTIN_TARGET_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
makefile=$src/cmd/make/bin/make.rules.file
output=/opt/illumos/mountin/kernel

# dmake asks the target linker to load its dependency-recording support
# library. Keep that library on the linker's search path without exposing the
# separate elfutils libelf used only by the CTF tools.
export LD_LIBRARY_PATH=/opt/schily/lib

run_make()
{
    directory=$1
    shift
    cd "$directory"
    dmake -r -f "$makefile" -f Makefile \
        "MAKE=dmake -r -f $makefile -f Makefile" \
        SRC="$src" CODEMGR_WS=/source \
        MACH=i386 MACH64=amd64 NATIVE_MACH=amd64 NATIVE_MACH64=amd64 \
        RELEASE_BUILD= NATIVE_OS=linux \
        GNU_ROOT=/opt/illumos-binutils \
        GNUC_ROOT=/usr NATIVE_GNUC_ROOT=/usr \
        ONBLD_TOOLS="$onbld" \
        "$@"
}

run_make "$src/uts/common/sys" all_h
run_make "$src/uts/common/rpc" all_h
run_make "$src/uts/intel" "$src/uts/common/os/priv_const.c"
run_make "$src/uts/intel/genunix" BUILD_TYPE=OBJ64 \
    "VERSION=SunOS Development" all.targ
run_make "$src/uts/i86pc/genassym" BUILD_TYPE=OBJ64 \
    "VERSION=SunOS Development" all.targ
run_make "$src/uts/i86pc/unix" BUILD_TYPE=OBJ64 \
    "VERSION=SunOS Development" all.targ

mkdir -p "$output"
install -m 0644 "$src/uts/intel/genunix/obj64/genunix" "$output/genunix"
install -m 0644 "$src/uts/i86pc/unix/obj64/unix" "$output/unix"

test -s "$output/genunix"
test -s "$output/unix"
