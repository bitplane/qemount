#!/bin/sh
# $1 = input directory
# $2 = output file
cd "$1"
find . | cpio -o -H newc > "$2"
