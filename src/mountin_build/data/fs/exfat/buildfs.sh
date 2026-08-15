#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 128M "$2"
mkfs.exfat "$2"
