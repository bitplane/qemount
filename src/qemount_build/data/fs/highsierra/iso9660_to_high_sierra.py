#!/usr/bin/env python3
"""Convert a plain ISO 9660 image into a High Sierra Format image.

High Sierra and ISO 9660 use the same extent and path-table model. Their
primary descriptors have different field offsets, while High Sierra directory
records replace ISO 9660's timezone byte with a reserved byte after the flags.
The layouts used here are the public ``hs_*`` structures in
``linux/iso_fs.h``.
"""

from __future__ import annotations

import argparse
from pathlib import Path


SECTOR_SIZE = 2048
PVD_SECTOR = 16
ISO_ID = b"CD001"
HS_ID = b"CDROM"


def directory_records(image: bytearray, extent: int, size: int):
    start = extent * SECTOR_SIZE
    end = start + size
    if start < 0 or end > len(image):
        raise ValueError(f"directory extent {extent}+{size} is outside image")

    pos = start
    while pos < end:
        length = image[pos]
        if length == 0:
            pos = ((pos // SECTOR_SIZE) + 1) * SECTOR_SIZE
            continue
        if length < 34 or pos + length > end:
            raise ValueError(f"invalid directory record at byte {pos}")
        yield pos, length
        pos += length


def collect_directories(image: bytearray, root: bytes) -> list[tuple[int, int]]:
    pending = [
        (
            int.from_bytes(root[2:6], "little"),
            int.from_bytes(root[10:14], "little"),
        )
    ]
    found: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()

    while pending:
        directory = pending.pop()
        if directory in seen:
            continue
        seen.add(directory)
        found.append(directory)

        for pos, _ in directory_records(image, *directory):
            flags = image[pos + 25]
            name_length = image[pos + 32]
            name = bytes(image[pos + 33 : pos + 33 + name_length])
            if flags & 0x02 and name not in (b"\x00", b"\x01"):
                pending.append(
                    (
                        int.from_bytes(image[pos + 2 : pos + 6], "little"),
                        int.from_bytes(image[pos + 10 : pos + 14], "little"),
                    )
                )

    return found


def convert_directory_record(record: bytearray) -> None:
    if len(record) < 34:
        raise ValueError("directory record is too short")

    # ISO: date[7], flags
    # HSF: date[6], flags, reserved
    record[24] = record[25]
    record[25] = 0


def convert_primary_descriptor(iso: bytes) -> bytearray:
    if len(iso) != SECTOR_SIZE or iso[1:6] != ISO_ID or iso[0] != 1:
        raise ValueError("sector 16 is not an ISO 9660 primary descriptor")

    hs = bytearray(SECTOR_SIZE)
    hs[8] = 1
    hs[9:14] = HS_ID
    hs[14] = iso[6]
    hs[16:48] = iso[8:40]
    hs[48:80] = iso[40:72]
    hs[80:88] = iso[72:80]
    hs[88:96] = iso[80:88]
    hs[96:128] = iso[88:120]
    hs[128:132] = iso[120:124]
    hs[132:136] = iso[124:128]
    hs[136:140] = iso[128:132]
    hs[140:148] = iso[132:140]
    hs[148:152] = iso[140:144]

    root = bytearray(iso[156:190])
    convert_directory_record(root)
    hs[180:214] = root

    # The remaining descriptive strings follow the root record in both
    # standards. They are not needed to locate data, but retaining them makes
    # the fixture useful to readers that expose volume metadata.
    hs[214:] = iso[190:2024]
    return hs


def convert(source: Path, destination: Path) -> None:
    image = bytearray(source.read_bytes())
    if len(image) % SECTOR_SIZE:
        raise ValueError("source image size is not a multiple of 2048 bytes")

    pvd_offset = PVD_SECTOR * SECTOR_SIZE
    iso_pvd = bytes(image[pvd_offset : pvd_offset + SECTOR_SIZE])
    if iso_pvd[1:6] != ISO_ID:
        raise ValueError("source does not contain a plain ISO 9660 descriptor")

    root = iso_pvd[156:190]
    directories = collect_directories(image, root)
    for extent, size in directories:
        for pos, length in directory_records(image, extent, size):
            record = image[pos : pos + length]
            convert_directory_record(record)
            image[pos : pos + length] = record

    image[pvd_offset : pvd_offset + SECTOR_SIZE] = convert_primary_descriptor(
        iso_pvd
    )

    # A plain genisoimage output has a primary descriptor followed by a
    # terminator. Convert every descriptor in that sequence and reject
    # unexpected supplementary descriptors rather than producing a hybrid.
    sector = PVD_SECTOR + 1
    while sector * SECTOR_SIZE < len(image):
        offset = sector * SECTOR_SIZE
        descriptor = bytes(image[offset : offset + SECTOR_SIZE])
        if descriptor[1:6] != ISO_ID:
            raise ValueError(f"unexpected descriptor at sector {sector}")
        if descriptor[0] == 255:
            terminator = bytearray(SECTOR_SIZE)
            terminator[8] = 255
            terminator[9:14] = HS_ID
            terminator[14] = descriptor[6]
            image[offset : offset + SECTOR_SIZE] = terminator
            break
        raise ValueError(
            f"source contains unsupported descriptor type {descriptor[0]}"
        )
    else:
        raise ValueError("source has no volume descriptor terminator")

    destination.write_bytes(image)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    convert(args.source, args.destination)


if __name__ == "__main__":
    main()
