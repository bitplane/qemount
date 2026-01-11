#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 150M "$2"
mkfs.nilfs2 "$2"
