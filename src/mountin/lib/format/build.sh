#!/bin/sh
set -e

mkdir -p /host/build/lib
python /build/compile.py /host/build/catalogue/format.json /host/build/lib/format.bin
