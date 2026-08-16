#!/usr/bin/env python3
"""
Hu-BASIC (Sharp X1) filesystem image creator — an mkfs for Hu-BASIC.

Formats a blank 2D floppy image (40 cyl x 2 sides x 16 sectors x 256 bytes =
327,680 bytes) with a Hu-BASIC filesystem and packs arbitrary host files into
it. Output is a *plain* .2d sector image (the raw disk), not a .d88 container.

Layout (2D), per the Hu-BASIC on-disk format (see docs/format/fs/hu-basic.md):

    sector size        256 bytes
    sectors / cluster  16            (1 cluster = 4096 bytes)
    clusters           80            (clusters 0..79)
    allocation table   sector 14     (one 256-byte sector for 2D)
    root directory     sector 16     (cluster 1, 16 sectors, 128 entries)
    cluster 0          boot / IPL    (reserved)

The allocation table is a FAT-style cluster chain. Each cluster has a low byte
at offset `c` (bit 7 = end-of-chain flag) and a high byte at offset `0x80 + c`;
the 14-bit value is `low7 | high<<7`. A terminal cluster stores
`0x80 | (sectors_used_in_last_cluster - 1)` in its low byte, so file length is
exact to the sector and trimmed to the byte count held in the directory entry.

Usage:
    mkhubasic.py OUTPUT.2d INPUT [INPUT ...]

Each input becomes a binary-type Hu-BASIC file (8.3-style names are widened to
the Hu-BASIC 13.3 limit). The writer rejects inputs that overflow the 78 free
data clusters or the 128-entry directory. Dates are written as zero for
reproducible builds.

This tool is filesystem-layer only: it lays down the Hu-BASIC directory and
allocation table. Wrapping the resulting raw image in a .d88 container, or
making an Atari/PC image, is a separate disk-image-layer step.
"""

import sys
from pathlib import Path

# ---- 2D geometry / Hu-BASIC parameters ----
SECTOR = 256
SECTORS_PER_CLUSTER = 16
CLUSTER_BYTES = SECTOR * SECTORS_PER_CLUSTER          # 4096
MAX_CLUSTER = 80
IMAGE_SIZE = MAX_CLUSTER * CLUSTER_BYTES              # 327680

FAT_SECTOR = 14
FAT_OFF = FAT_SECTOR * SECTOR
DIR_SECTOR = 16
DIR_OFF = DIR_SECTOR * SECTOR
DIR_SECTORS = SECTORS_PER_CLUSTER                     # cluster 1
DIR_ENTRIES = DIR_SECTORS * 8                         # 8 entries per sector -> 128
ENTRY_SIZE = 32

FIRST_DATA_CLUSTER = 2                                # 0 = boot, 1 = directory
ENTRY_END = 0xFF                                      # unused directory slot
ENTRY_DELETE = 0x00
MODE_BINARY = 0x01
PASSWORD_NONE = 0x20

MAX_NAME = 13
MAX_EXT = 3


def sectors_for(length: int) -> int:
    return max(1, (length + SECTOR - 1) // SECTOR)


def clusters_for(length: int) -> int:
    return (sectors_for(length) + SECTORS_PER_CLUSTER - 1) // SECTORS_PER_CLUSTER


def hu_name(host_name: str) -> tuple[str, str]:
    """Map a host filename to a (name<=13, ext<=3) pair, upper-cased ASCII."""
    p = Path(host_name)
    stem = "".join(c for c in p.stem.upper() if c.isalnum() or c in "_-")[:MAX_NAME]
    ext = "".join(c for c in p.suffix[1:].upper() if c.isalnum())[:MAX_EXT]
    if not stem:
        raise ValueError(f"cannot derive a Hu-BASIC name from {host_name!r}")
    return stem, ext


def set_fat(img: bytearray, cluster: int, value: int, end: bool) -> None:
    """Write one allocation-table entry (low byte + high byte)."""
    low = (value & 0x7F) | (0x80 if end else 0x00)
    img[FAT_OFF + cluster] = low
    img[FAT_OFF + 0x80 + cluster] = value >> 7


def format_disk() -> bytearray:
    """Return a blank but formatted 2D Hu-BASIC image."""
    img = bytearray(IMAGE_SIZE)

    # Allocation table (sector 14). Cluster 0 = boot (chains to 1), cluster 1 =
    # directory (terminal, uses all 16 sectors). Clusters 80..127 do not exist
    # on a 2D disk, so they are fenced off as 0x8f and never allocated.
    img[FAT_OFF + 0] = 0x01
    img[FAT_OFF + 1] = 0x8F
    for i in range(0x50, 0x80):
        img[FAT_OFF + i] = 0x8F

    # Root directory: every entry slot starts as 0xFF (end / empty).
    for i in range(DIR_OFF, DIR_OFF + DIR_SECTORS * SECTOR):
        img[i] = 0xFF

    return img


def write_entry(img: bytearray, slot: int, name: str, ext: str,
                size: int, start_cluster: int,
                load: int = 0, exec_: int = 0) -> None:
    """Write a 32-byte directory entry into directory slot `slot`."""
    off = DIR_OFF + slot * ENTRY_SIZE
    img[off + 0x00] = MODE_BINARY
    img[off + 0x01:off + 0x01 + MAX_NAME] = name.ljust(MAX_NAME).encode("ascii")
    img[off + 0x0E:off + 0x0E + MAX_EXT] = ext.ljust(MAX_EXT).encode("ascii")
    img[off + 0x11] = PASSWORD_NONE
    img[off + 0x12:off + 0x14] = size.to_bytes(2, "little")
    img[off + 0x14:off + 0x16] = load.to_bytes(2, "little")
    img[off + 0x16:off + 0x18] = exec_.to_bytes(2, "little")
    # Date/time (6 BCD bytes) left zero for reproducibility; the 6th byte is
    # overwritten by the start-cluster high bits, matching the reference writer.
    img[off + 0x18:off + 0x1D] = b"\x00\x00\x00\x00\x00"
    img[off + 0x1D] = (start_cluster >> 14) & 0x7F
    img[off + 0x1E] = start_cluster & 0x7F
    img[off + 0x1F] = (start_cluster >> 7) & 0x7F


def add_file(img: bytearray, slot: int, next_free: int,
             name: str, ext: str, data: bytes) -> int:
    """Place one file's data + directory entry. Returns the new free cluster."""
    need = clusters_for(len(data))
    if next_free + need > MAX_CLUSTER:
        raise ValueError("disk full: not enough free clusters")

    clusters = list(range(next_free, next_free + need))

    # Lay the data into the clusters' sectors.
    for i, c in enumerate(clusters):
        chunk = data[i * CLUSTER_BYTES:(i + 1) * CLUSTER_BYTES]
        base = c * CLUSTER_BYTES
        img[base:base + len(chunk)] = chunk

    # Allocation-table chain: link all but the last, then mark the terminal.
    for c, nxt in zip(clusters, clusters[1:]):
        set_fat(img, c, nxt, end=False)
    sectors_in_last = sectors_for(len(data)) - (need - 1) * SECTORS_PER_CLUSTER
    set_fat(img, clusters[-1], sectors_in_last - 1, end=True)

    write_entry(img, slot, name, ext, len(data), clusters[0])
    return next_free + need


def create_image(output: Path, files: list[tuple[str, bytes]]) -> None:
    if len(files) > DIR_ENTRIES:
        raise ValueError(f"too many files: {len(files)} > {DIR_ENTRIES}")

    img = format_disk()
    next_free = FIRST_DATA_CLUSTER
    used = set()
    for slot, (host_name, data) in enumerate(files):
        name, ext = hu_name(host_name)
        key = (name, ext)
        if key in used:
            raise ValueError(f"duplicate Hu-BASIC name {name}.{ext}")
        used.add(key)
        next_free = add_file(img, slot, next_free, name, ext, data)

    verify_roundtrip(img, files)
    output.write_bytes(img)


def extract_all(img: bytes) -> list[tuple[str, bytes]]:
    """Read the directory + allocation table back out (used to self-check)."""
    out = []
    for slot in range(DIR_ENTRIES):
        off = DIR_OFF + slot * ENTRY_SIZE
        mode = img[off]
        if mode == ENTRY_END:
            break
        if mode == ENTRY_DELETE:
            continue
        name = img[off + 0x01:off + 0x01 + MAX_NAME].decode("ascii").rstrip(" ")
        ext = img[off + 0x0E:off + 0x0E + MAX_EXT].decode("ascii").rstrip(" ")
        size = int.from_bytes(img[off + 0x12:off + 0x14], "little")
        start = img[off + 0x1E] | (img[off + 0x1F] << 7) | (img[off + 0x1D] << 14)

        data = bytearray()
        c = start
        while True:
            low = img[FAT_OFF + c]
            end = (low & 0x80) != 0
            count = (low & 0x0F) + 1 if end else SECTORS_PER_CLUSTER
            base = c * CLUSTER_BYTES
            data += img[base:base + count * SECTOR]
            if end:
                break
            c = low | (img[FAT_OFF + 0x80 + c] << 7)
        fname = f"{name}.{ext}" if ext else name
        out.append((fname, bytes(data[:size])))
    return out


def verify_roundtrip(img: bytes, files: list[tuple[str, bytes]]) -> None:
    """Read the image back and assert every file decodes to its input bytes."""
    got = extract_all(img)
    if len(got) != len(files):
        raise AssertionError(f"round-trip: {len(got)} files != {len(files)} written")
    for (hn, want), (gname, gdata) in zip(files, got):
        if gdata != want:
            raise AssertionError(f"round-trip mismatch for {hn} ({gname})")


def main() -> int:
    if len(sys.argv) < 3:
        sys.stderr.write(__doc__.strip().splitlines()[0] + "\n")
        sys.stderr.write("usage: mkhubasic.py OUTPUT.2d INPUT [INPUT ...]\n")
        return 2

    output = Path(sys.argv[1])
    files = [(p, Path(p).read_bytes()) for p in sys.argv[2:]]
    create_image(output, files)
    sys.stdout.write(
        f"wrote {output} ({output.stat().st_size} bytes, {len(files)} files)\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
