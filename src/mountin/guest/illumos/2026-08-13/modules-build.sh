#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
makefile=$src/cmd/make/bin/make.rules.file
output=/opt/illumos/mountin/modules
kernel=/opt/illumos/mountin/kernel

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
        "$@"
}

rm -rf "$output"
mkdir -p "$output"

# Module CTF data is uniquified against genunix. The kernel is a separate
# provider, so place its proven output where the native module rules expect it.
mkdir -p "$src/uts/intel/genunix/obj64" "$src/uts/i86pc/unix/obj64"
install -m 0644 "$kernel/genunix" "$src/uts/intel/genunix/obj64/genunix"
install -m 0644 "$kernel/unix" "$src/uts/i86pc/unix/obj64/unix"

run_make "$src/uts/common/sys" all_h
run_make "$src/uts/common/rpc" all_h
run_make "$src/uts/intel" "$src/uts/common/os/priv_const.c"

while read -r directory destination aliases; do
    case "$directory" in
        ''|'#'*) continue ;;
    esac

    echo "Building illumos module: $destination"
    run_make "$src/uts/$directory" BUILD_TYPE=OBJ64 \
        "VERSION=SunOS Development" all.targ

    module=${destination##*/}
    source_file=$src/uts/$directory/obj64/$module
    echo "Installing illumos module: $source_file"
    test -s "$source_file"
    mkdir -p "$output/${destination%/*}"
    install -m 0644 "$source_file" "$output/$destination"

    for alias in $aliases; do
        mkdir -p "$output/${alias%/*}"
        ln "$output/$destination" "$output/$alias"
    done
done < /build/modules.list

while read -r source_file destination; do
    case "$source_file" in
        ''|'#'*) continue ;;
    esac

    mkdir -p "$output/${destination%/*}"
    install -m 0644 "$src/uts/$source_file" "$output/$destination"
done < /build/configs.list
