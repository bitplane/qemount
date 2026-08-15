#!/bin/sh
# $1 = input directory
# $2 = output file

# Tux3 was never in mainline Linux so we can only create a
# minimal formatted image for detection testing.
# mkfs.tux3 will not size an empty file itself, so pre-size it first.
truncate -s 10M "$2"
mkfs.tux3 "$2"
