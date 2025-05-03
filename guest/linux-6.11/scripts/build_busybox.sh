#!/bin/bash
set -euo pipefail

# Parse arguments
BUSYBOX_VERSION="$1"
KERNEL_ARCH="$2"
BUSYBOX_CONFIG_FILE=$(readlink -f "$3")  # Full path to the merged config
CACHE_DIR=$(readlink -f "$4")
BUSYBOX_INSTALL_DIR=$(readlink -f "$5")
CROSS_COMPILE_PREFIX="$6"

# Setup paths
BUSYBOX_SRC_DIR="$CACHE_DIR/busybox-$BUSYBOX_VERSION"

# Configure and build BusyBox
echo "Building BusyBox in $BUSYBOX_SRC_DIR using config $BUSYBOX_CONFIG_FILE"
cd "$BUSYBOX_SRC_DIR"

# Start with allnoconfig (minimum features)
make allnoconfig >/dev/null 2>&1

# Apply our custom config directly using sed to modify the .config file
# Process each line in our custom config file
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip comments and empty lines
  [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]] && continue
  
  # Extract the config name and value
  name=$(echo "$line" | cut -d'=' -f1)
  value=$(echo "$line" | cut -d'=' -f2)
  
  # Use sed to replace or add the config option
  if grep -q "^$name=" .config; then
    sed -i "s|^$name=.*|$name=$value|" .config
  else
    echo "$name=$value" >> .config
  fi
done < "$BUSYBOX_CONFIG_FILE"

# Run oldconfig to resolve dependencies
make oldconfig >/dev/null 2>&1 || true

# Verify our critical settings were applied
if grep -q "CONFIG_TC=y" .config; then
  echo "WARNING: Failed to disable TC module. Manually removing..."
  sed -i 's/CONFIG_TC=y/CONFIG_TC=n/' .config
  sed -i 's/CONFIG_FEATURE_TC_INGRESS=y/CONFIG_FEATURE_TC_INGRESS=n/' .config
  # Rebuild config with these forced changes
  make oldconfig >/dev/null 2>&1 || true
fi

# Double-check critical settings
if grep -q "CONFIG_TC=y" .config; then
  echo "ERROR: Still failed to disable TC module. Aborting."
  exit 1
fi

# Build BusyBox
make -j"$(nproc)"

# Install BusyBox
echo "Installing BusyBox to $BUSYBOX_INSTALL_DIR"
rm -rf "$BUSYBOX_INSTALL_DIR"
mkdir -p "$BUSYBOX_INSTALL_DIR"
make CONFIG_PREFIX="$BUSYBOX_INSTALL_DIR" install

echo "BusyBox built and installed successfully!"
exit 0