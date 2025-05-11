#!/bin/sh
set -euo pipefail

ARCH="$1"
BUILD_ARCH=$(uname -m)
TARGET_TRIPLE="$2"

# Download and setup cross toolchain
wget -qO- "https://musl.cc/${TARGET_TRIPLE}-cross.tgz" | tar -xz -C /opt/

# Create symlinks
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-gcc" /usr/bin/target-gcc
ln -sf "/opt/${TARGET_TRIPLE}-cross/bin/${TARGET_TRIPLE}-g++" /usr/bin/target-g++
# ... etc

# Add to PATH
export PATH="/opt/${TARGET_TRIPLE}-cross/bin:${PATH}"

# Detect endianness
ENDIAN="little"
case "$ARCH" in
    s390x|sparc|sparc64) ENDIAN="big" ;;
    mips|powerpc) ENDIAN="big" ;;  # Usually, but can vary
esac

# Create meson cross file
cat > /usr/share/meson/cross/cross.ini <<EOF
[binaries]
c = 'target-gcc'
cpp = 'target-g++'
ar = 'target-ar'
strip = 'target-strip'

[host_machine]
system = 'linux'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = '${ENDIAN}'

[properties]
needs_exe_wrapper = true
EOF
