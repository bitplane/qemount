#!/usr/bin/env python3
"""Wrap a raw floppy sector image in an APRIDISK container.

Usage: mkapridisk.py INPUT.img OUTPUT.apridisk

Lays the input out as APRIDISK sector records at Apricot HD geometry
(80 tracks x 2 heads x 18 sectors x 512 bytes). Sectors that are a single
repeated byte are stored RLE-compressed; the rest are stored raw. A leading
comment record exercises the reader's record-skipping path.

Format reference: docs/format/disk/apridisk.md
"""

import struct
import sys

MAGIC = b"ACT Apricot disk image\x1a\x04"
HEADER_SIZE = 128
SECTOR_SIZE = 512

TRACKS = 80
HEADS = 2
SECTORS_PER_TRACK = 18

APR_SECTOR = 0xE31D0001
APR_COMMENT = 0xE31D0002
APR_UNCOMPRESSED = 0x9E90
APR_COMPRESSED = 0x3E5A


def record_header(rtype, compression, data_size, head=0, sector=0, track=0):
    # type(I) compression(H) header_size(H) data_size(I) head(B) sector(B) track(H)
    return struct.pack(
        "<IHHIBBH",
        rtype,
        compression,
        16,
        data_size,
        head,
        sector,
        track,
    )


def main():
    if len(sys.argv) != 3:
        print("usage: mkapridisk.py INPUT OUTPUT", file=sys.stderr)
        return 1

    with open(sys.argv[1], "rb") as f:
        data = f.read()

    total = TRACKS * HEADS * SECTORS_PER_TRACK
    expected = total * SECTOR_SIZE
    if len(data) != expected:
        print(
            f"input must be {expected} bytes ({total} sectors), got {len(data)}",
            file=sys.stderr,
        )
        return 1

    out = bytearray()
    out += MAGIC
    out += b"\x00" * (HEADER_SIZE - len(MAGIC))

    # Comment record (skipped by readers) to exercise the record-skip path.
    comment = b"qemount apridisk test fixture"
    out += record_header(APR_COMMENT, APR_UNCOMPRESSED, len(comment))
    out += comment

    for lba in range(total):
        sec = data[lba * SECTOR_SIZE : (lba + 1) * SECTOR_SIZE]
        track, rem = divmod(lba, HEADS * SECTORS_PER_TRACK)
        head, idx = divmod(rem, SECTORS_PER_TRACK)
        sector = idx + 1  # sectors are 1-based

        if sec.count(sec[0]) == SECTOR_SIZE:
            # RLE: u16 length + fill byte.
            out += record_header(APR_SECTOR, APR_COMPRESSED, 3, head, sector, track)
            out += struct.pack("<H", SECTOR_SIZE) + bytes([sec[0]])
        else:
            out += record_header(
                APR_SECTOR, APR_UNCOMPRESSED, SECTOR_SIZE, head, sector, track
            )
            out += sec

    with open(sys.argv[2], "wb") as f:
        f.write(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
