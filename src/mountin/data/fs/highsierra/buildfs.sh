#!/bin/sh
set -eu

source_iso=/tmp/high-sierra-source.iso
genisoimage -V MOUNTIN_HIGH_SIERRA -o "$source_iso" "$1"
python3 /build/iso9660_to_high_sierra.py "$source_iso" "$2"
