#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/fuse-2.9.9.tar.gz
cd fuse-2.9.9

./configure \
    --host="$MOUNTIN_TARGET_PLATFORM" \
    --prefix=/opt/fuse \
    --disable-shared \
    --enable-static \
    --disable-example \
    --disable-util
make -j"$MOUNTIN_BUILD_JOBS" -C include install
make -j"$MOUNTIN_BUILD_JOBS" -C lib install
install -Dm644 fuse.pc /opt/fuse/lib/pkgconfig/fuse.pc

cd /work
tar -xf /host/build/sources/9pfuse-mountin-2026-08-15.tar.gz
cd 9pfuse-mountin-2026-08-15

cat > /work/target.cross <<EOF
[binaries]
c = '$CC'
ar = '$AR'
strip = '$STRIP'
pkg-config = 'pkg-config'

[built-in options]
c_link_args = ['-static', '-L/opt/fuse/lib']

[properties]
needs_exe_wrapper = true

[host_machine]
system = 'linux'
cpu_family = '$MOUNTIN_TARGET_ARCH'
cpu = '$MOUNTIN_TARGET_ARCH'
endian = 'little'
EOF

export PKG_CONFIG_LIBDIR=/opt/fuse/lib/pkgconfig
meson setup build \
    --cross-file=/work/target.cross \
    --default-library=static \
    --prefer-static

meson compile -C build

mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v build/9pfuse /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
"$STRIP" /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/9pfuse
