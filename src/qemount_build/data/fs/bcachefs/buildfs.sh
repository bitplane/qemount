#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
# bcachefs needs more space for metadata overhead
truncate -s 128M "$2"
bcachefs format "$2"
