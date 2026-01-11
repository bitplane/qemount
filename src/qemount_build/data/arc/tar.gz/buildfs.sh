#!/bin/sh
# $1 = input directory
# $2 = output file
tar -czf "$2" -C "$1" .
