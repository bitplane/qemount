#!/bin/sh
# $1 = input directory
# $2 = output file
genromfs -f "$2" -d "$1" -V "basic"
