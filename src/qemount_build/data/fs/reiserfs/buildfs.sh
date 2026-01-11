#!/bin/sh
# $1 = input directory (unused, QEMU handles copying)
# $2 = output file
truncate -s 64M "$2"
mkreiserfs -q "$2"
