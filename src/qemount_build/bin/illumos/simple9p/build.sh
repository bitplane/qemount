#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

src=/source/usr/src
onbld=$src/tools/proto/root_i386-nd/opt/onbld
sysroot=/host/build/bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
source=/work/simple9p
objects=/work/objects
output=/host/build/bin/${OUTPUT_PLATFORM}/simple9p

rm -rf "$source" "$objects"
mkdir -p "$source" "$objects/libixp" "${output%/*}"
tar -xf /host/build/sources/simple9p-0.6.2.tar.xz \
    -C "$source" --strip-components=1

compile()
{
    input=$1
    object=$2
    shift 2
    "$onbld/bin/i386/cw" \
        --tag target \
        --linker "$onbld/bin/amd64/ld" \
        --primary gcc12,/usr/bin/gcc,gnu \
        -- \
        -m64 \
        -_gcc=-Os \
        -_gcc=-fno-stack-protector \
        -_gcc=-nostdinc \
        -xc99=%all \
        -D_XOPEN_SOURCE=700 \
        -D_REENTRANT \
        -DSIMPLE9P_NO_NETWORK \
        -DS9_PATH_MAX=1024 \
        -I"$sysroot/usr/include" \
        -I"$source" \
        -I"$source/libixp/include" \
        "$@" \
        -c "$input" \
        -o "$object"
}

for name in convert error map message request server transport util timer \
        thread; do
    compile "$source/libixp/lib/libixp/$name.c" \
        "$objects/libixp/$name.o"
done

for name in simple9p alloc path namespace fs_ops fs_io fs_stat fs_dir; do
    compile "$source/$name.c" "$objects/$name.o"
done
compile "$source/platform_posix.c" "$objects/platform_posix.o" \
    -_gcc=-include -_gcc=sys/time.h -D_ATFILE_SOURCE

"$onbld/bin/amd64/ld" \
    -o "$output" \
    -e _start \
    -I /lib/amd64/ld.so.1 \
    -z defs \
    -R /lib/amd64 \
    -L"$sysroot/lib/amd64" \
    "$sysroot/usr/lib/amd64/crt1.o" \
    "$sysroot/usr/lib/amd64/crti.o" \
    "$objects/simple9p.o" \
    "$objects/alloc.o" \
    "$objects/path.o" \
    "$objects/namespace.o" \
    "$objects/platform_posix.o" \
    "$objects/fs_ops.o" \
    "$objects/fs_io.o" \
    "$objects/fs_stat.o" \
    "$objects/fs_dir.o" \
    "$objects"/libixp/*.o \
    -lc \
    "$sysroot/usr/lib/amd64/crtn.o"

/usr/bin/strip --strip-unneeded "$output"
/usr/bin/readelf -d "$output" \
    | grep -q 'Shared library: \[libc.so.1\]'
