#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
set -e

printf 'lower case\n' > "$1/basic/case.txt"
printf 'upper case\n' > "$1/basic/CASE.txt"

truncate -s 16M "$2"
mkfs.hfsplus -s "$2"
