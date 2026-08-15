#!/bin/sh
set -eu

exec /usr/local/libexec/netbsd-gcc \
    --sysroot="${NETBSD_SYSROOT}" "$@"
