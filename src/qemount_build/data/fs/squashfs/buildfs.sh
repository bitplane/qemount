#!/bin/sh
# $1 = input directory
# $2 = output file
mksquashfs "$1" "$2" -comp gzip
