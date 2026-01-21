#!/bin/sh
set -e

mkdir -p /host/build/lib
python /build/compile.py /host/build/catalogue.json /host/build/lib/format.bin
