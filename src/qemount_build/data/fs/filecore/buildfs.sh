#!/bin/sh
set -eu

input=$1
output=$2
commands=/tmp/filecore.commands

{
    echo 'new ADFS HDD NN20M'
    echo 'title basic'
    printf 'add "%s"\n' "$input/*"
    printf 'save "%s"\n' "$output"
    echo 'exit'
} > "$commands"

disc-image-manager -s "$commands" -n
test -s "$output"
