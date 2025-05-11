#!/bin/sh
set -euo pipefail

# For native builds, just use system tools directly
ln -sf /usr/bin/gcc /usr/bin/target-gcc
ln -sf /usr/bin/g++ /usr/bin/target-g++
ln -sf /usr/bin/ar /usr/bin/target-ar
ln -sf /usr/bin/ld /usr/bin/target-ld
ln -sf /usr/bin/strip /usr/bin/target-strip
ln -sf /usr/bin/objcopy /usr/bin/target-objcopy  
ln -sf /usr/bin/nm /usr/bin/target-nm

# No cross compilation variables needed
unset CROSS_COMPILE

# No meson cross file needed for native builds
# But create empty one in case something looks for it
mkdir -p /usr/share/meson/cross
touch /usr/share/meson/cross/cross.ini