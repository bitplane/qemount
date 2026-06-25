#!/usr/bin/env python3
"""
SCL (Sinclair TR-DOS) image writer.

Packs arbitrary host files into an SCL image: the "SINCLAIR" signature, a
one-byte file count, a 14-byte TR-DOS catalogue entry per file, the file data
padded to whole 256-byte sectors, and a trailing 32-bit checksum.

Each input file becomes a TR-DOS "Code" file (type 'C') with a load address.
Host names are mapped to 8-character, space-padded TR-DOS names (extension
dropped, upper-cased); duplicate names after mapping are an error.

Usage:
    mkscl.py OUTPUT.scl INPUT [INPUT ...]
    mkscl.py --addr 0x6000 OUTPUT.scl INPUT [INPUT ...]

The output is a valid SCL that reconstructs onto a 640K DS80 TR-DOS disk, so
the writer rejects inputs that would overflow that disk (128 files / 2544 free
sectors).
"""

import argparse
import struct
import sys
from pathlib import Path


SECTOR = 256            # TR-DOS sector size, bytes
MAGIC = b"SINCLAIR"
MAX_FILES = 128         # TR-DOS catalogue capacity
DS80_FREE_SECTORS = 2544  # 80*2*16 sectors minus the 16-sector track 0


def sectors_for(length: int) -> int:
    """Whole 256-byte sectors needed to hold `length` bytes."""
    return (length + SECTOR - 1) // SECTOR


def trdos_name(host_name: str) -> str:
    """Map a host filename to an 8-char TR-DOS name (extension dropped)."""
    stem = Path(host_name).stem.upper()
    name = "".join(c for c in stem if c.isalnum() or c in "_-")[:8]
    if not name:
        raise ValueError(f"cannot derive a TR-DOS name from {host_name!r}")
    return name


def dir_entry(name: str, ftype: str, param1: int, length: int) -> bytes:
    """Build a 14-byte SCL catalogue entry."""
    return (
        name.encode("ascii").ljust(8, b" ")
        + ftype.encode("ascii")
        + struct.pack("<H", param1 & 0xFFFF)
        + struct.pack("<H", length & 0xFFFF)
        + struct.pack("B", sectors_for(length))
    )


def create_scl(output_path: Path, files: list[tuple[str, bytes]], addr: int):
    """
    files: list of (trdos_name, data) tuples, already name-mapped.
    addr:  load address recorded for each Code file.
    """
    if len(files) > MAX_FILES:
        raise ValueError(f"too many files: {len(files)} > {MAX_FILES}")

    total_sectors = sum(sectors_for(len(data)) for _, data in files)
    if total_sectors > DS80_FREE_SECTORS:
        raise ValueError(
            f"data needs {total_sectors} sectors, DS80 disk holds "
            f"{DS80_FREE_SECTORS}"
        )

    body = bytearray()
    body += MAGIC
    body += struct.pack("B", len(files))

    # Catalogue: one 14-byte entry per file.
    for name, data in files:
        body += dir_entry(name, "C", addr, len(data))

    # Data: each file padded up to a whole number of sectors.
    for _name, data in files:
        body += data.ljust(sectors_for(len(data)) * SECTOR, b"\x00")

    # Trailing 32-bit checksum: sum of every preceding byte. Most readers
    # ignore it, but it is part of the format, so we emit a correct one.
    body += struct.pack("<I", sum(body) & 0xFFFFFFFF)

    output_path.write_bytes(body)


def collect(inputs: list[str]) -> list[tuple[str, bytes]]:
    """Read each input file and assign a unique TR-DOS name."""
    files = []
    used = set()
    for path in inputs:
        p = Path(path)
        name = trdos_name(p.name)
        if name in used:
            raise ValueError(f"duplicate TR-DOS name {name!r} from {path!r}")
        used.add(name)
        files.append((name, p.read_bytes()))
    return files


def main():
    parser = argparse.ArgumentParser(description="Pack files into an SCL image.")
    parser.add_argument("output", help="output .scl path")
    parser.add_argument("inputs", nargs="+", help="files to pack")
    parser.add_argument(
        "--addr",
        type=lambda s: int(s, 0),
        default=0x8000,
        help="load address for Code files (default 0x8000)",
    )
    args = parser.parse_args()

    files = collect(args.inputs)
    output = Path(args.output)
    create_scl(output, files, args.addr)
    sys.stdout.write(
        f"wrote {output} ({output.stat().st_size} bytes, {len(files)} files)\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
