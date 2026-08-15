#!/bin/sh
set -e

OUTPUT_PATH="$1"
INPUT="/host/build/data/templates/basic.tar"

mkdir -p /tmp/template
tar -xf "$INPUT" -C /tmp/template

# Copy UHARC binary into the working directory so DOS can see it
cp /usr/local/share/uharc/UHARCD.EXE /tmp/template/basic/

# Run UHARC under DOSBox (headless, no sound)
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
dosbox -nointro \
    -c "MOUNT C /tmp/template/basic" \
    -c "C:" \
    -c "UHARCD.EXE a -y OUTPUT.UHA HELLO.TXT SCRIPT.SH" \
    -c "EXIT"

mkdir -p "$(dirname "/host/build/$OUTPUT_PATH")"
cp /tmp/template/basic/OUTPUT.UHA "/host/build/$OUTPUT_PATH"
