#!/bin/sh
# $1 = input directory
# $2 = output file
tar -cf - -C "$1" . | zstd -o "$2"
