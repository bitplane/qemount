#!/usr/bin/env python3
"""
Wrap a raw ProDOS-order disk image in a 2IMG / 2MG header.

2IMG is a self-describing 64-byte header prepended to a raw Apple sector image
(see docs/format/disk/2img.md). This emits the ProDOS-order variant: the input
is copied verbatim after the header, and the header records its offset/length so
the `disk/2img` container can strip it back off.

Usage:
    mk2img.py OUTPUT.2mg INPUT
"""

import sys
from pathlib import Path

HEADER_LEN = 0x40
DATA_FORMAT_PRODOS = 1      # 0 = DOS 3.3 order, 1 = ProDOS order, 2 = NIB


def main() -> int:
    if len(sys.argv) != 3:
        sys.stderr.write("usage: mk2img.py OUTPUT.2mg INPUT\n")
        return 2
    out, inp = Path(sys.argv[1]), Path(sys.argv[2])
    data = inp.read_bytes()

    hdr = bytearray(HEADER_LEN)
    hdr[0x00:0x04] = b"2IMG"
    hdr[0x04:0x08] = b"QMNT"                                   # creator id
    hdr[0x08:0x0A] = HEADER_LEN.to_bytes(2, "little")          # header length
    hdr[0x0A:0x0C] = (1).to_bytes(2, "little")                 # version
    hdr[0x0C:0x10] = DATA_FORMAT_PRODOS.to_bytes(4, "little")  # data format
    hdr[0x10:0x14] = (0).to_bytes(4, "little")                 # flags
    hdr[0x14:0x18] = (len(data) // 512).to_bytes(4, "little")  # ProDOS blocks
    hdr[0x18:0x1C] = HEADER_LEN.to_bytes(4, "little")          # offset to data
    hdr[0x1C:0x20] = len(data).to_bytes(4, "little")           # length of data
    # comment/creator chunk fields (0x20..0x2F) and reserved (0x30..0x3F): zero

    out.write_bytes(bytes(hdr) + data)
    sys.stdout.write(
        f"wrote {out} ({out.stat().st_size} bytes; 2IMG header + {len(data)} data)\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
