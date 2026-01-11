#!/bin/sh
# $1 = input directory
# $2 = output file
genisoimage -r -J -o "$2" "$1"
