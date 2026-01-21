#!/bin/sh
set -e

cd /work

# Extract sources
tar -xf /host/build/sources/simple9p-qemount-0.1.tar.gz
tar -xf /host/build/sources/libixp-qemount-0.1.tar.gz

# Build libixp
cd /work/libixp-qemount-0.1
mkdir -p install/lib install/include
for f in lib/libixp/*.c; do
    echo "Compiling $f..."
    gcc -Iinclude -DVERSION=\"0.5\" -D_POSIX_C_SOURCE=200809L -c -o "${f%.c}.o" "$f"
done
ar rcs install/lib/libixp.a lib/libixp/*.o
cp include/ixp.h install/include/

# Build simple9p statically linked against libixp
cd /work/simple9p-qemount-0.1
LIBIXP=/work/libixp-qemount-0.1/install
gcc -static -I$LIBIXP/include -o simple9p simple9p.c path.c fs_dir.c fs_io.c fs_ops.c fs_stat.c -L$LIBIXP/lib -lixp
strip simple9p

# Copy to output
mkdir -p /host/build/bin/${ARCH}-linux-${ENV}
cp -v simple9p /host/build/bin/${ARCH}-linux-${ENV}/
