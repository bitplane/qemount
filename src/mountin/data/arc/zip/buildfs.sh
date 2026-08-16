#!/bin/sh
# $1 = input directory
# $2 = output file
cd "$1"
zip -r "$2" .
