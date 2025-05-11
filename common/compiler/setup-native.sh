#!/bin/sh
set -euo pipefail

# For native builds, symlink system tools to our standard names
for tool in gcc g++ ar ld strip objcopy nm; do
    # Create both target-* and ${TARGET_TRIPLE}- symlinks
    ln -sf "/usr/bin/${tool}" "/usr/bin/target-${tool}"
    ln -sf "/usr/bin/${tool}" "/usr/bin/${TARGET_TRIPLE}-${tool}"
done

echo "Native compilation setup complete"