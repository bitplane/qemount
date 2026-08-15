#!/bin/sh
# $1 = input directory
# $2 = output file
set -eu

case "$(basename "$2")" in
    basic.iso9660)
        genisoimage -V MOUNTIN_ISO9660 -o "$2" "$1"
        ;;
    basic.rock-ridge.iso9660)
        genisoimage -r -V MOUNTIN_ROCK_RIDGE -o "$2" "$1"
        ;;
    basic.joliet.iso9660)
        genisoimage -J -V MOUNTIN_JOLIET -o "$2" "$1"
        ;;
    *)
        echo "Unknown ISO 9660 fixture: $2" >&2
        exit 1
        ;;
esac
