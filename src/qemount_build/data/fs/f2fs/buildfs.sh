#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 100M "$2"
mkfs.f2fs "$2"
