#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 300M "$2"
mkfs.xfs -f "$2"
