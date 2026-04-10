#!/bin/sh
# $1 = input directory
# $2 = output file

mkfs.xiafs -d "$1" "$2" 10
