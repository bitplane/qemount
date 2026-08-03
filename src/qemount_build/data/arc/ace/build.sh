#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"
SOURCE="/host/build/sources/acefile-qemount-0.2.tar.gz"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

mkdir -p /tmp/acefile
tar -xf "$SOURCE" -C /tmp/acefile --strip-components=1

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
PYTHONPATH=/tmp/acefile python3 -c '
import sys
from pathlib import Path

import acefile

with acefile.open(sys.argv[1], "w") as archive:
    for path in sys.argv[2:]:
        archive.write(path, Path(path).name)
' "/host/build/$OUTPUT_PATH" \
    /tmp/template/basic/hello.txt \
    /tmp/template/basic/script.sh
