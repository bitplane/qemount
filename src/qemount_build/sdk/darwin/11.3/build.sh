#!/bin/sh
set -eu

archive=/host/build/sources/MacOSX11.3.sdk.tar.xz
output_root=/host/build/sdk/darwin/11.3
output=$output_root/MacOSX11.3.sdk
mkdir -p "$output_root"
work=$(mktemp -d "$output_root/.extract.XXXXXX")

cleanup() {
    rm -rf "$work"
}
trap cleanup EXIT HUP INT TERM

tar --no-same-owner -xJf "$archive" -C "$work"
test -d "$work/MacOSX11.3.sdk/usr/include"
sha256sum "$archive" | cut -d ' ' -f 1 \
    > "$work/MacOSX11.3.sdk/.qemount-source-hash"

rm -rf "$output"
mv "$work/MacOSX11.3.sdk" "$output"
