#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: build.sh OUTPUT_DIRECTORY" >&2
    exit 2
fi

output=/host/build/$1
source=/host/build/sources/mountin
work=/cache/source

rm -rf "$work"
mkdir -p "$work" "$output"
cp -a "$source"/. "$work"/

cd "$work"
python -m build --no-isolation --outdir "$output"
python -m twine check "$output"/*
