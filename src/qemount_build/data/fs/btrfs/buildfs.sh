#!/bin/sh
# $1 = input directory
# $2 = output file
truncate -s 64M "$2"
mkfs.btrfs -q --rootdir "$1" "$2"
