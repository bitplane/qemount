#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 32M "$2"
mkfs.ntfs -F "$2"
