#!/bin/sh
# $1 = input directory
# $2 = output file

mkfs.mfs -d "$1" -v "Test" "$2"
