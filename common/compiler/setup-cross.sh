#!/bin/sh
set -euo pipefail

ARCH="$1"
BUILD_ARCH=$(uname -m)

# Map architecture to correct musl.cc toolchain name
case "$ARCH" in
    x86_64)   TARGET_TRIPLE="x86_64-linux-musl" ;;
    aarch64)  TARGET_TRIPLE="aarch64-linux-musl" ;;
    arm)      TARGET_TRIPLE="arm-linux-musleabi" ;;
    armhf)    TARGET_TRIPLE="arm-linux-musleabihf" ;;
    armv7l)   TARGET_TRIPLE="armv7l-linux-musleabihf" ;;
    i386)     TARGET_TRIPLE="i486-linux-musl" ;;  # Note: i486, not i386!
    i686)     TARGET_TRIPLE="i686-linux-musl" ;;
    mips)     TARGET_TRIPLE="mips-linux-musl" ;;
    mipsel)   TARGET_TRIPLE="mipsel-linux-musl" ;;
    powerpc)  TARGET_TRIPLE="powerpc-linux-musl" ;;
    powerpc64) TARGET_TRIPLE="powerpc64-linux-musl" ;;
    powerpc64le) TARGET_TRIPLE="powerpc64le-linux-musl" ;;
    s390x)    TARGET_TRIPLE="s390x-linux-musl" ;;
    *)        TARGET_TRIPLE="${ARCH}-linux-musl" ;;
esac

echo "Setting up cross compilation for $ARCH"
echo "Target triple: $TARGET_TRIPLE"

# Download cross toolchain
DOWNLOAD_URL="https://musl.cc/${TARGET_TRIPLE}-cross.tgz"
echo "Downloading from: $DOWNLOAD_URL"

if ! wget -O /tmp/cross-toolchain.tgz "$DOWNLOAD_URL"; then
    echo "Failed to download cross toolchain from $DOWNLOAD_URL"
    exit 1
fi

echo "Extracting toolchain..."
tar -xzf /tmp/cross-toolchain.tgz -C /opt/
rm /tmp/cross-toolchain.tgz

# Create symlinks
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-gcc" /usr/bin/target-gcc
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-g++" /usr/bin/target-g++
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-ar" /usr/bin/target-ar
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-ld" /usr/bin/target-ld
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-strip" /usr/bin/target-strip
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-objcopy" /usr/bin/target-objcopy
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-nm" /usr/bin/target-nm

# Add to PATH
export PATH="/opt/${TARGET_TRIPLE}-cross/bin:${PATH}"

# Set cross compilation prefix
export CROSS_COMPILE="${TARGET_TRIPLE}-"

# Detect endianness
ENDIAN="little"
case "$ARCH" in
    mips|powerpc|powerpc64|s390x|sparc|sparc64) ENDIAN="big" ;;
    mipsel|powerpc64le) ENDIAN="little" ;;
esac

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
endian = '${ENDIAN}'

[properties]
needs_exe_wrapper = true
exe_wrapper = ['qemu-${ARCH}-static', '-L', '/opt/${TARGET_TRIPLE}-cross/${TARGET_TRIPLE}/']
EOF

echo "Cross compilation setup complete for ${ARCH} (${TARGET_TRIPLE})"