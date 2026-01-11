#!/bin/sh
# $1 = input directory
# $2 = output file

# Remove symlinks - Linux 2.6 sysv driver crashes on symlink creation
find "$1" -type l -delete

# Note: mkfs.sysv creates the file, no need for truncate
mkfs.sysv "$2" 10
