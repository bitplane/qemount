#!/usr/bin/env python3
"""Create simple ACE 2.0 archives using the uncompressed (stored) method."""

from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path
import struct
import zlib


ACE_MAGIC = b"**ACE**"
TYPE_MAIN = 0
TYPE_FILE32 = 1
FLAG_ADDSIZE = 1 << 0
FLAG_V20FORMAT = 1 << 8
HOST_WIN32 = 2
COMP_STORED = 0
ATTR_ARCHIVE = 0x20


def ace_crc32(data: bytes) -> int:
    """Return ACE's non-inverted variant of the standard CRC-32."""
    return zlib.crc32(data) ^ 0xFFFFFFFF


def header(body: bytes) -> bytes:
    if len(body) > 0xFFFF:
        raise ValueError("ACE header is too large")
    return struct.pack("<HH", ace_crc32(body) & 0xFFFF, len(body)) + body


def dos_datetime(timestamp: float) -> int:
    value = dt.datetime.fromtimestamp(timestamp)
    # The DOS timestamp has a 1980 epoch and stores seconds in two-second units.
    value = min(
        max(value, dt.datetime(1980, 1, 1)),
        dt.datetime(2107, 12, 31, 23, 59, 58),
    )
    return (
        ((value.year - 1980) << 25)
        | (value.month << 21)
        | (value.day << 16)
        | (value.hour << 11)
        | (value.minute << 5)
        | (value.second // 2)
    )


def main_header(timestamp: float) -> bytes:
    body = struct.pack(
        "<BH7sBBBBL8s",
        TYPE_MAIN,
        FLAG_V20FORMAT,
        ACE_MAGIC,
        20,  # ACE 2.0 required to extract
        20,  # ACE 2.0 creator
        HOST_WIN32,
        0,  # first and only volume
        dos_datetime(timestamp),
        b"\0" * 8,
    )
    return header(body)


def file_record(path: Path, archive_name: str) -> bytes:
    data = path.read_bytes()
    if len(data) > 0xFFFFFFFF:
        raise ValueError(f"file is too large for a 32-bit ACE record: {path}")
    try:
        name = archive_name.encode("cp437")
    except UnicodeEncodeError as exc:
        raise ValueError(
            f"filename is not representable in ACE's OEM encoding: {archive_name}"
        ) from exc
    if len(name) > 0xFFFF:
        raise ValueError(f"filename is too long: {archive_name}")

    body = struct.pack(
        "<BHLLLLLBBHHH",
        TYPE_FILE32,
        FLAG_ADDSIZE,
        len(data),
        len(data),
        dos_datetime(path.stat().st_mtime),
        ATTR_ARCHIVE,
        ace_crc32(data),
        COMP_STORED,
        0,  # compression quality is irrelevant for stored data
        0,  # decompressor parameters
        0,  # reserved
        len(name),
    ) + name
    return header(body) + data


def create_archive(output: Path, inputs: list[Path]) -> None:
    if not inputs:
        raise ValueError("at least one input file is required")
    duplicate_names: set[str] = set()
    records: list[bytes] = []
    for path in inputs:
        if not path.is_file():
            raise ValueError(f"not a regular file: {path}")
        archive_name = path.name
        folded = archive_name.casefold()
        if folded in duplicate_names:
            raise ValueError(f"duplicate archive filename: {archive_name}")
        duplicate_names.add(folded)
        records.append(file_record(path, archive_name))

    timestamp = max(path.stat().st_mtime for path in inputs)
    payload = main_header(timestamp) + b"".join(records)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(f".{output.name}.tmp-{os.getpid()}")
    try:
        temporary.write_bytes(payload)
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="output .ace archive")
    parser.add_argument("inputs", nargs="+", type=Path, help="files to add")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        create_archive(args.output, args.inputs)
    except (OSError, ValueError) as exc:
        raise SystemExit(f"mkace.py: {exc}") from exc


if __name__ == "__main__":
    main()
