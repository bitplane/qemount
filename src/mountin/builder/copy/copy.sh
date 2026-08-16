#!/bin/sh
set -eu

if [ "$#" -eq 0 ]; then
    echo "usage: mountin-copy OUTPUT [...]" >&2
    exit 2
fi

while [ "$#" -gt 0 ]; do
    destination_path=$1
    shift

    requirement_count=$(printf '%s' "$META" | jq \
        --arg output "$destination_path" \
        '.provides[$output].requires // {} | length')
    if [ "$requirement_count" -ne 1 ]; then
        echo "copy output must require exactly one source: $destination_path" >&2
        exit 2
    fi
    source_path=$(printf '%s' "$META" | jq -r \
        --arg output "$destination_path" \
        '.provides[$output].requires |
         if type == "array" then .[0] else keys[0] end')

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
