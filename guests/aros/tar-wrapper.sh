#!/bin/sh
# Wrapper for tar that adds --no-same-owner to avoid container ownership issues
# Handles -- argument separator correctly

args=""
found_separator=0
for arg in "$@"; do
    if [ "$arg" = "--" ]; then
        args="$args --no-same-owner --"
        found_separator=1
    else
        args="$args $arg"
    fi
done

if [ $found_separator -eq 0 ]; then
    args="$args --no-same-owner"
fi

exec /bin/tar.real $args
