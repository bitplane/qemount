#!/bin/sh
# $1 = input directory
# $2 = output file
mkfs.erofs "$2" "$1"
