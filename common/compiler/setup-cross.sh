#!/bin/sh
set -euo pipefail

ARCH="$1"

# Map our architecture names to musl.cc's toolchain names
case "$ARCH" in
    x86_64)   MUSL_TRIPLE="x86_64-linux-musl" ;;
    aarch64)  MUSL_TRIPLE="aarch64-linux-musl" ;;
    arm)      MUSL_TRIPLE="arm-linux-musleabi" ;;
    armhf)    MUSL_TRIPLE="arm-linux-musleabihf" ;;
    i386)     MUSL_TRIPLE="i486-linux-musl" ;;
    *)        MUSL_TRIPLE="${ARCH}-linux-musl" ;;
esac

echo "Setting up cross compilation:"
echo "  Architecture: $ARCH"
echo "  Our triple: $TARGET_TRIPLE"
echo "  Musl triple: $MUSL_TRIPLE"

# Download musl cross-compiler
wget -q "https://musl.cc/${MUSL_TRIPLE}-cross.tgz" || exit 1
tar -xzf "${MUSL_TRIPLE}-cross.tgz" -C /opt/
rm "${MUSL_TRIPLE}-cross.tgz"

# Create symlinks from musl's tool names to our standard names
for tool in gcc g++ ar ld strip objcopy nm; do
    # Create target-* symlinks
    ln -sf "/opt/${MUSL_TRIPLE}-cross/bin/${MUSL_TRIPLE}-${tool}" "/usr/bin/target-${tool}"
    # Create our standard ${TARGET_TRIPLE}- symlinks
    ln -sf "/opt/${MUSL_TRIPLE}-cross/bin/${MUSL_TRIPLE}-${tool}" "/usr/bin/${TARGET_TRIPLE}-${tool}"
done

# Add musl's bin to PATH
export PATH="/opt/${MUSL_TRIPLE}-cross/bin:${PATH}"

# Create meson cross file
mkdir -p /usr/share/meson/cross
cat > /usr/share/meson/cross/cross.ini <<EOF
[binaries]
c = 'target-gcc'
cpp = 'target-g++'
ar = 'target-ar'
strip = 'target-strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'

[properties]
needs_exe_wrapper = true
EOF

echo "Cross compilation setup complete"