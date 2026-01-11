#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 16M "$2"
mkfs.hfsplus "$2"
