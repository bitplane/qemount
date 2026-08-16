#!/bin/sh
set -eu

if [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
    echo "usage: mountin-copy SOURCE DESTINATION [...]" >&2
    exit 2
fi

while [ "$#" -gt 0 ]; do
    source_path=$1
    destination_path=$2
    shift 2

    for path in "$source_path" "$destination_path"; do
        case "$path" in
            /*|..|../*|*/..|*/../*)
                echo "copy paths must be relative and may not contain '..'" >&2
                exit 2
                ;;
        esac
    done

    source_path=/host/build/$source_path
    destination_path=/host/build/$destination_path

    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
        echo "copy source does not exist: $source_path" >&2
        exit 1
    fi
    if [ "$source_path" = "$destination_path" ]; then
        echo "copy source and destination are the same: $source_path" >&2
        exit 2
    fi
    if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
        echo "copy destination already exists: $destination_path" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$destination_path")"
    cp -a "$source_path" "$destination_path"
done
