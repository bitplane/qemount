#!/bin/sh
# $1 = input directory
# $2 = output file

# Note: mkfs.sysv creates the file, no need for truncate
mkfs.sysv -d "$1" "$2" 10
