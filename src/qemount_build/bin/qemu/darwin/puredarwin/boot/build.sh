#!/bin/sh
set -eu

SOURCE=/host/build/sources/aros-ports/grub-2.12.tar.gz
OUTPUT_DIR=/host/build/bin/qemu/x86_64-darwin/puredarwin/boot
SOURCE_DIR=/work/grub
BUILD_DIR=/work/build
INSTALL_DIR=/work/install
CONFIG=/work/grub.cfg

rm -rf "$SOURCE_DIR" "$BUILD_DIR" "$INSTALL_DIR"
mkdir -p "$SOURCE_DIR" "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"
tar -xzf "$SOURCE" -C "$SOURCE_DIR" --strip-components=1
# GRUB 2.12's release archive accidentally omitted this tracked build input.
printf '%s\n' 'depends bli part_gpt' > "$SOURCE_DIR/grub-core/extra_deps.lst"

cd "$BUILD_DIR"
"$SOURCE_DIR/configure" \
    --target=i386 \
    --with-platform=pc \
    --prefix="$INSTALL_DIR" \
    --disable-device-mapper \
    --enable-efiemu \
    --disable-grub-mkfont \
    --disable-liblzma \
    --disable-nls \
    --disable-werror
# The EFI runtime is freestanding.  Prevent GCC from replacing its internal
# byte loops with calls to libc functions that do not exist after GRUB boots.
TARGET_CC="i686-linux-gnu-gcc -fno-tree-loop-distribute-patterns -fno-pie -no-pie"
make -j"${JOBS:-1}" TARGET_CC="$TARGET_CC"
make install TARGET_CC="$TARGET_CC"

cat > "$CONFIG" <<'EOF'
serial --unit=0 --speed=115200
terminal_output serial
set root=(hd0,msdos1)
set prefix=($root)/boot/grub
configfile /boot/grub/grub.cfg
EOF

cp "$INSTALL_DIR/lib/grub/i386-pc/boot.img" "$OUTPUT_DIR/boot.img.tmp"
cp "$INSTALL_DIR/lib/grub/i386-pc/efiemu64.o" "$OUTPUT_DIR/efiemu64.o.tmp"
"$INSTALL_DIR/bin/grub-mkimage" \
    -O i386-pc \
    -o "$OUTPUT_DIR/core.img.tmp" \
    -p /boot/grub \
    -c "$CONFIG" \
    biosdisk part_msdos hfsplus serial terminal configfile echo efiemu xnu

mv "$OUTPUT_DIR/boot.img.tmp" "$OUTPUT_DIR/boot.img"
mv "$OUTPUT_DIR/core.img.tmp" "$OUTPUT_DIR/core.img"
mv "$OUTPUT_DIR/efiemu64.o.tmp" "$OUTPUT_DIR/efiemu64.o"
