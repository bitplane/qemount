#!/usr/bin/env python3
"""Build an MBR -> Solaris2 -> x86 VTOC16 -> UFS fixture."""

import struct
import sys
from pathlib import Path


SECTOR_SIZE = 512
MBR_PARTITION_START = 2048
SLICE_START = 128
SOLARIS2_PARTITION_TYPE = 0xBF
VTOC_SANITY = 0x600DDEEE
VTOC_MAGIC = 0xDABE
VTOC_PARTITIONS = 16
VTOC_ROOT_TAG = 2
VTOC_BACKUP_TAG = 5


def sectors(size: int) -> int:
    if size % SECTOR_SIZE:
        raise ValueError("UFS fixture is not sector-aligned")
    return size // SECTOR_SIZE


def write_mbr(image: bytearray, partition_size: int) -> None:
    entry = 446
    image[entry + 4] = SOLARIS2_PARTITION_TYPE
    struct.pack_into("<II", image, entry + 8, MBR_PARTITION_START, partition_size)
    image[510:512] = b"\x55\xaa"


def write_vtoc(image: bytearray, partition_size: int, slice_size: int) -> None:
    label_offset = (MBR_PARTITION_START + 1) * SECTOR_SIZE
    label = bytearray(SECTOR_SIZE)

    struct.pack_into("<III", label, 0, 0, 0, 0)
    struct.pack_into("<II", label, 12, VTOC_SANITY, 1)
    label[20:28] = b"qemount\0"
    struct.pack_into("<HH", label, 28, SECTOR_SIZE, VTOC_PARTITIONS)

    # Slice 0 contains the UFS fixture. Slice 2 is the conventional raw backup
    # slice describing the complete enclosing Solaris partition.
    struct.pack_into("<HHIi", label, 72, VTOC_ROOT_TAG, 0, SLICE_START, slice_size)
    struct.pack_into("<HHIi", label, 72 + 2 * 12, VTOC_BACKUP_TAG, 1, 0, partition_size)

    ascii_label = b"qemount Solaris x86"
    label[328 : 328 + len(ascii_label)] = ascii_label
    struct.pack_into("<IIHHII", label, 456, 1, 1, 0, 0, 1, 63)
    struct.pack_into("<H", label, 508, VTOC_MAGIC)

    checksum = 0
    for offset in range(0, 510, 2):
        checksum ^= struct.unpack_from("<H", label, offset)[0]
    struct.pack_into("<H", label, 510, checksum)
    image[label_offset : label_offset + SECTOR_SIZE] = label


def main() -> None:
    source = Path(sys.argv[1]).read_bytes()
    slice_size = sectors(len(source))
    partition_size = SLICE_START + slice_size + 2048
    total_sectors = MBR_PARTITION_START + partition_size + 2048
    image = bytearray(total_sectors * SECTOR_SIZE)

    write_mbr(image, partition_size)
    write_vtoc(image, partition_size, slice_size)

    payload_offset = (MBR_PARTITION_START + SLICE_START) * SECTOR_SIZE
    image[payload_offset : payload_offset + len(source)] = source
    Path(sys.argv[2]).write_bytes(image)


if __name__ == "__main__":
    main()
