#!/usr/bin/env python3
"""Wrap a raw Atari disk sector image in a 16-byte ATR container header.

Usage: mkatr.py OUTPUT.atr INPUT.raw [sector_size]

The ATR header records the magic word 0x0296, the data size in 16-byte
paragraphs, and the sector size (default 128). See docs/format/disk/atr.md.
"""

import sys

ATR_MAGIC = 0x0296
HEADER_LEN = 16


def main(argv):
    if len(argv) not in (3, 4):
        print("usage: mkatr.py OUTPUT.atr INPUT.raw [sector_size]", file=sys.stderr)
        return 1
    output, src = argv[1], argv[2]
    sector_size = int(argv[3]) if len(argv) == 4 else 128

    with open(src, "rb") as f:
        raw = f.read()
    paragraphs = len(raw) // 16

    hdr = bytearray(HEADER_LEN)
    hdr[0] = ATR_MAGIC & 0xFF
    hdr[1] = (ATR_MAGIC >> 8) & 0xFF
    hdr[2] = paragraphs & 0xFF
    hdr[3] = (paragraphs >> 8) & 0xFF
    hdr[4] = sector_size & 0xFF
    hdr[5] = (sector_size >> 8) & 0xFF
    hdr[6] = (paragraphs >> 16) & 0xFF
    hdr[7] = (paragraphs >> 24) & 0xFF

    with open(output, "wb") as f:
        f.write(bytes(hdr) + raw)
    print(f"mkatr: wrote {output} ({HEADER_LEN + len(raw)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
