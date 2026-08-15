#!/bin/sh
# $1 = input directory
# $2 = output file
makefs -t ffs -o version=1 -s 10m "$2" "$1"
