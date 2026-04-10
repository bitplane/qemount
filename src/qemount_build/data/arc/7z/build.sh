#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

7z a /tmp/output.7z /tmp/template/*

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/output.7z "/host/build/$OUTPUT_PATH"
