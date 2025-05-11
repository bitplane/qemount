#!/bin/sh
# common/scripts/arch_to_platform.sh
arch=${1:-$(uname -m)}
case "$arch" in
 x86_64|amd64|x64) echo linux/amd64;;
 i[3-6]86|x86) echo linux/386;;
 aarch64|arm64|armv8*) echo linux/arm64;;
 armv7*|armhf) echo linux/arm/v7;;
 armv6*) echo linux/arm/v6;;
 arm*) echo linux/arm;;
 ppc64le) echo linux/ppc64le;;
 ppc64) echo linux/ppc64;;
 s390x) echo linux/s390x;;
 riscv64) echo linux/riscv64;;
 mips64le) echo linux/mips64le;;
 mips64) echo linux/mips64;;
 *) echo "linux/$arch";;
esac