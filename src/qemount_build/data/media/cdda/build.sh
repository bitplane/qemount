#!/bin/sh
set -e

OUTPUT="/host/build/$1"
mkdir -p "$(dirname "$OUTPUT")"

# Stephen Hawking quote from Pink Floyd's "Keep Talking"
TEXT="For millions of years, mankind lived just like the animals. Then something happened, which unleashed the power of our imagination. We learned to talk."

# Generate speech with espeak-ng (slower pace for Hawking-like delivery)
# Convert to CDDA format: 44.1kHz, 16-bit signed stereo, little-endian
espeak-ng -v en-us -s 120 "$TEXT" --stdout | \
    ffmpeg -y -i - -ar 44100 -ac 2 -f s16le -acodec pcm_s16le "$OUTPUT"

echo "Generated: $OUTPUT"
