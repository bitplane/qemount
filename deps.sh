#!/bin/bash
set -euo pipefail

echo "Installing system dependencies..."

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  flex \
  bison \
  libssl-dev \
  libelf-dev \
  bc \
  qemu-system-x86 \
  cpio \
  wget \
  gzip \
  pigz \
  xz-utils \
  genisoimage \
  git \
  bsdextrautils  # for `hexdump` and other tools

echo "Dependencies installed."
