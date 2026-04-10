#!/bin/bash
set -ex

cd /work

# Build libaal first
tar xf /host/build/sources/libaal-1.0.7.tar.gz
cd libaal-1.0.7
./configure --prefix=/opt/libaal --enable-static --disable-shared
make -j$(nproc)
make install
cd /work

# Build reiser4progs
tar xf /host/build/sources/reiser4progs-1.2.2.tar.gz
cd reiser4progs-1.2.2
./configure \
    --enable-full-static \
    --disable-shared \
    --disable-readline \
    --with-libaal=/opt/libaal \
    CFLAGS="-I/opt/libaal/include" \
    LDFLAGS="-L/opt/libaal/lib"
make -j$(nproc)

mkdir -p /host/build/bin/${HOST_ARCH}-linux-gnu
# Binary may be in progs/mkfs/ or mkfs.reiser4/ depending on version
find . -name mkfs.reiser4 -type f -executable | head -1 | xargs cp -v -t /host/build/bin/${HOST_ARCH}-linux-gnu/
# busy tool for userspace file manipulation (create/cp/ls without mounting)
cp -v $(find . -name busy -type f -executable | head -1) /host/build/bin/${HOST_ARCH}-linux-gnu/reiser4-busy
