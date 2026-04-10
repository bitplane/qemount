#!/bin/sh
# $1 = input directory
# $2 = output file

# Tux3 was never in mainline Linux so we can only create a
# minimal formatted image for detection testing.
mkfs.tux3 "$2"
