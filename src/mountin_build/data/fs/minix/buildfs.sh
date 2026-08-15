#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 10M "$2"
mkfs.minix "$2"
