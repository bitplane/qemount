#!/bin/sh
# $1 = input directory
# $2 = output file
# Note: SCO BFS can't be populated from Linux, just create empty filesystem
dd if=/dev/zero of="$2" bs=1M count=10
mkfs.bfs -v "$2"
