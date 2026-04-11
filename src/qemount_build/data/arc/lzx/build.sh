#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

# Set up Amiga directory structure for vamos
mkdir -p /tmp/amiga/C /tmp/amiga/L /tmp/amiga/S /tmp/amiga/T /tmp/amiga/work
cp /opt/lzx/LZX_68000EC-r /tmp/amiga/C/lzx
chmod +x /tmp/amiga/C/lzx
cp /opt/lzx/LZX.Keyfile /tmp/amiga/L/

# Copy template files into work area
cp /tmp/template/basic/hello.txt /tmp/amiga/work/
cp /tmp/template/basic/script.sh /tmp/amiga/work/

# Note: LZX looks for L:lzx.keyfile (case-insensitive on Amiga)
cp /opt/lzx/LZX.Keyfile /tmp/amiga/L/lzx.keyfile

/opt/vamos/bin/vamos \
    -V "SYS:/tmp/amiga" \
    -V "WORK:/tmp/amiga/work" \
    -a "L:SYS:L" \
    -p "SYS:C" \
    --cwd "WORK:" \
    lzx a output.lzx hello.txt script.sh

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/amiga/work/output.lzx "/host/build/$OUTPUT_PATH"
