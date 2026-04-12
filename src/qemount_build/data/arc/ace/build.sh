#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

# Pre-init Wine prefix to avoid noisy first-run output
export WINEDEBUG=-all
export WINEPREFIX=/tmp/wine
wineboot --init 2>/dev/null || true

# ACE treats / as switch prefix like UHARC, so work in a local dir
cd /tmp/template/basic
wine /usr/local/share/ace/ACE32.EXE a -y output.ace hello.txt script.sh

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp output.ace "/host/build/$OUTPUT_PATH"
