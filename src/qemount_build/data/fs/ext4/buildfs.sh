#!/bin/sh
# $1 = input directory
# $2 = output file
truncate -s 10M "$2"
mke2fs -t ext4 -d "$1" "$2"
