#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/schilytools-2024-03-21.tar.gz
SOURCE_DIR=/work/schilytools
OUTPUT_DIR=/host/build/bin/${TARGET_PLATFORM}

mkdir -p /work
tar -xzf "$SOURCE_ARCHIVE" -C /work
source_root=$(find /work -mindepth 1 -maxdepth 1 -type d -name 'schilytools*' | head -n 1)
test -n "$source_root"
mv "$source_root" "$SOURCE_DIR"

cd "$SOURCE_DIR/psmake"
./MAKE-all

cd "$SOURCE_DIR/libgetopt"
../psmake/smake

xarch=$(find "$SOURCE_DIR/incs" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | head -n 1)
test -n "$xarch"
minimal_dir=$SOURCE_DIR/libs/$xarch/minimal
mkdir -p "$minimal_dir"

for source in findinpath getexecpath eaccess geterrno seterrno strcatl
do
    cc -O2 -DSCHILY_BUILD -D_GNU_SOURCE -DPORT_ONLY \
        -I"$SOURCE_DIR/incs/$xarch" \
        -I"$SOURCE_DIR/include" \
        -c "$SOURCE_DIR/libschily/$source.c" \
        -o "$minimal_dir/$source.o"
done
ar rcs "$SOURCE_DIR/libs/$xarch/libschily.a" "$minimal_dir"/*.o

cd "$SOURCE_DIR/sunpro"
../psmake/smake COPTX=-Wno-error=incompatible-pointer-types

binary=$SOURCE_DIR/sunpro/Make/bin/make/common/OBJ/$xarch/make
support=$(find "$SOURCE_DIR/libs" -type f \
    -name 'libmakestate.so*' | head -n 1)
test -x "$binary"
test -n "$support"
mkdir -p "$OUTPUT_DIR"
cp "$binary" "$OUTPUT_DIR/dmake"
mkdir -p "$OUTPUT_DIR/lib"
cp "$support" "$OUTPUT_DIR/lib/libmakestate.so.1"
mkdir -p "$OUTPUT_DIR/lib/64"
cp "$support" "$OUTPUT_DIR/lib/64/libmakestate.so.1"

ELFUTILS_DIR=/work/elfutils
tar -xjf /host/build/sources/elfutils-0.194.tar.bz2 -C /work
mv /work/elfutils-0.194 "$ELFUTILS_DIR"
cd "$ELFUTILS_DIR"
./configure \
    --prefix=/work/elfutils-install \
    --disable-debuginfod \
    --disable-libdebuginfod \
    --disable-nls \
    --without-bzlib \
    --without-lzma \
    --without-zstd
make -j"${BUILD_JOBS:-1}" -C lib all
make -j"${BUILD_JOBS:-1}" -C libelf install
cp /work/elfutils-install/lib/libelf.so.1 "$OUTPUT_DIR/lib/64/libelf.so.1"
