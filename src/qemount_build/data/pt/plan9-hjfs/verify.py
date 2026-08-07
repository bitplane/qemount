#!/usr/bin/env python3

import struct
import sys
from pathlib import Path


SECTOR_SIZE = 512
HJFS_HEADER = bytes.fromhex("011ce50d6e")


def main() -> None:
    image = Path(sys.argv[1])
    with image.open("rb") as stream:
        mbr = stream.read(SECTOR_SIZE)
        if len(mbr) != SECTOR_SIZE or mbr[510:512] != b"\x55\xaa":
            raise SystemExit("Plan 9 fixture has no valid MBR")

        entries = []
        for index in range(4):
            offset = 446 + index * 16
            type_code = mbr[offset + 4]
            start, length = struct.unpack_from("<II", mbr, offset + 8)
            if type_code == 0x39 and start and length:
                entries.append((start, length))
        if len(entries) != 1:
            raise SystemExit(f"Expected one Plan 9 MBR partition, found {len(entries)}")

        outer_start, outer_length = entries[0]
        stream.seek((outer_start + 1) * SECTOR_SIZE)
        table = stream.read(SECTOR_SIZE).split(b"\0", 1)[0].decode("ascii")
        parts = {}
        for line in table.splitlines():
            keyword, name, start, end = line.split()
            if keyword != "part":
                raise SystemExit(f"Invalid Plan 9 partition line: {line}")
            parts[name] = (int(start), int(end))

        if set(parts) != {"fs"}:
            raise SystemExit(f"Expected only an fs partition, found: {sorted(parts)}")
        fs_start, fs_end = parts["fs"]
        if not 2 <= fs_start < fs_end <= outer_length:
            raise SystemExit("Plan 9 fs partition extends outside its MBR partition")

        stream.seek((outer_start + fs_start) * SECTOR_SIZE)
        if stream.read(len(HJFS_HEADER)) != HJFS_HEADER:
            raise SystemExit("Plan 9 fs partition does not contain HJFS")


if __name__ == "__main__":
    main()

