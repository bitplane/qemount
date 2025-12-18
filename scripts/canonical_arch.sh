#!/bin/sh
# Normalize architecture name to canonical form
arch=${1:-$(uname -m)}
case "$arch" in
 amd64|x64) echo x86_64;;
 i[3-6]86|x86) echo i386;;
 arm64|armv8*) echo aarch64;;
 armv7*|armhf) echo armv7;;
 armv6*) echo armv6;;
 arm*) echo arm;;
 mips*) echo mips;;
 *) echo "$arch";;
esac