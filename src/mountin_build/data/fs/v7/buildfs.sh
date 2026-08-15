#!/bin/sh
# $1 = input directory
# $2 = output file
# V7 filesystem - 4MB should be plenty for test data
makefs -t v7fs -s 4194304 "$2" "$1"
