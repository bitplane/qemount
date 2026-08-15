#!/bin/sh
set -eu

exec clang-14 \
    --target=x86_64-apple-macos10.13 \
    -isysroot "${PUREDARWIN_SYSROOT}" \
    -mmacosx-version-min=10.13 \
    -fuse-ld=lld \
    "$@"
