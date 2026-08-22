#!/bin/sh
set -eu

exec /opt/aros-toolchain/i386-aros-gcc \
    --sysroot="${AROS_SYSROOT}" "$@"
