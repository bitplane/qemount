#!/bin/sh
set -eu

exec /usr/local/libexec/haiku-gcc \
    --sysroot="${HAIKU_SYSROOT}" "$@"
