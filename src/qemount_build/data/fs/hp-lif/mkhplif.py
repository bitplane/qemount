#!/usr/bin/env python3
"""mkhplif - build an HP LIF (Logical Interchange Format) volume.

Usage: mkhplif.py OUTPUT.lif SRC_DIR

Packs the regular files under SRC_DIR into a fresh LIF volume (a flat, single
directory with contiguous file allocation). LIF has no subdirectories, so the
tree is flattened and names are sanitised to 10 characters.

LIF is block-granular: a directory entry records a file's length only in whole
256-byte blocks, with no byte-count field (per MAME's fs_hplif.cpp, size is
sector_count * 256). Files are therefore stored zero-padded to a block boundary,
and the round-trip self-test verifies that block-padded content - the exact
length is not a property LIF can represent here.

This is a test-fixture generator, not a reader: qemount defers filesystem
reading to the original system in an emulator. Layout per MAME's fs_hplif.cpp
and the lif(4) manual; see docs/format/fs/hp-lif.md.
"""

import math
import os
import struct
import sys

# ---- Layout ----

BLOCK = 256
MAGIC = 0x8000  # LIF system word, big-endian, at offset 0 of block 0
LIF_ID = 0x1000  # LIF identifier (System 3000)
LIF_VERSION = 1

DIR_START = 2  # directory begins at block 2 (blocks 0-1 are the header area)
DIR_BLOCKS = 14
DATA_START = DIR_START + DIR_BLOCKS  # block 16
TOTAL_BLOCKS = 1056  # 270,336-byte LIF floppy
IMAGE_SIZE = TOTAL_BLOCKS * BLOCK

ENTRY_LEN = 32
ENTRIES_PER_BLOCK = BLOCK // ENTRY_LEN  # 8
MAX_ENTRIES = DIR_BLOCKS * ENTRIES_PER_BLOCK  # 112

TYPE_END = 0xFFFF  # terminates the directory
TYPE_FREE = 0x0000  # purged slot (reader keeps scanning)
FILE_TYPE = 0xE020  # generic binary file type (nonzero, not a terminator)
VOLUME_NUMBER = 0x8001

VOLUME_LABEL = "QMOUNT"  # 6 chars


def block_off(block):
    return block * BLOCK


class LifVolume:
    def __init__(self, label=VOLUME_LABEL):
        self.image = bytearray(IMAGE_SIZE)
        self.label = label
        self.entries = []  # (name, start_block, block_count, byte_len)
        self.next_block = DATA_START

    def add_file(self, name, data):
        if len(self.entries) >= MAX_ENTRIES - 1:  # leave room for the 0xFFFF end
            raise ValueError("directory full")

        n = len(data)
        nblocks = max(1, math.ceil(n / BLOCK))
        if self.next_block + nblocks > TOTAL_BLOCKS:
            raise ValueError("volume full")

        start = self.next_block
        off = block_off(start)
        self.image[off : off + n] = data  # remainder of last block stays zero
        self.next_block += nblocks

        self.entries.append((name, start, nblocks, n))

    def _write_header(self):
        h = self.image
        struct.pack_into(">H", h, 0, MAGIC)
        h[2:8] = self.label.ljust(6).encode("ascii")[:6]
        struct.pack_into(">I", h, 8, DIR_START)
        struct.pack_into(">H", h, 12, LIF_ID)
        struct.pack_into(">I", h, 16, DIR_BLOCKS)
        struct.pack_into(">H", h, 20, LIF_VERSION)
        # timestamp at offset 36 left zero (reproducible)

    def _write_dir(self):
        for k, (name, start, count, _blen) in enumerate(self.entries):
            off = block_off(DIR_START) + k * ENTRY_LEN
            e = bytearray(ENTRY_LEN)
            e[0:10] = name.ljust(10).encode("ascii")[:10]
            struct.pack_into(">H", e, 10, FILE_TYPE)
            struct.pack_into(">I", e, 12, start)
            struct.pack_into(">I", e, 16, count)
            # bytes 20-25 time (zero), 26-27 volume number, 28-31 general purpose
            struct.pack_into(">H", e, 26, VOLUME_NUMBER)
            self.image[off : off + ENTRY_LEN] = e
        # Explicit end-of-directory marker (0x0000 would mean "purged, keep going").
        term = block_off(DIR_START) + len(self.entries) * ENTRY_LEN
        struct.pack_into(">H", self.image, term + 10, TYPE_END)

    def build(self):
        self._write_header()
        self._write_dir()
        return bytes(self.image)


# ---- Round-trip reader (self-test only) ----


def extract(image):
    """Return {name: block-padded bytes} by walking the LIF directory."""
    out = {}
    (magic,) = struct.unpack_from(">H", image, 0)
    if magic != MAGIC:
        raise ValueError("not a LIF volume")
    (dir_start,) = struct.unpack_from(">I", image, 8)
    (dir_blocks,) = struct.unpack_from(">I", image, 16)
    max_entries = dir_blocks * ENTRIES_PER_BLOCK

    for k in range(max_entries):
        off = block_off(dir_start) + k * ENTRY_LEN
        (ftype,) = struct.unpack_from(">H", image, off + 10)
        if ftype == TYPE_END:
            break
        if ftype == TYPE_FREE:
            continue
        name = image[off : off + 10].decode("ascii").rstrip()
        (start,) = struct.unpack_from(">I", image, off + 12)
        (count,) = struct.unpack_from(">I", image, off + 16)
        data = image[block_off(start) : block_off(start + count)]
        out[name] = bytes(data)
    return out


def lif_name(path, used):
    stem = os.path.basename(path)
    if "." in stem:
        stem = stem.rsplit(".", 1)[0]
    stem = "".join(c for c in stem.upper() if c.isalnum())
    name = (stem or "FILE")[:10]
    n = 1
    while name in used:
        suffix = str(n)
        name = (stem or "FILE")[: 10 - len(suffix)] + suffix
        n += 1
    used.add(name)
    return name


def build_tree(vol, src):
    expected = {}  # name -> block-padded bytes
    used = set()
    for root, _dirs, files in sorted(os.walk(src)):
        for fname in sorted(files):
            path = os.path.join(root, fname)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            name = lif_name(path, used)
            with open(path, "rb") as f:
                data = f.read()
            vol.add_file(name, data)
            padded = data + bytes(-len(data) % BLOCK)
            expected[name] = padded
    return expected


def verify_roundtrip(image, expected):
    got = extract(image)
    if got != expected:
        miss = set(expected) - set(got)
        extra = set(got) - set(expected)
        bad = [k for k in expected if k in got and got[k] != expected[k]]
        raise SystemExit(
            f"round-trip mismatch: missing={miss} extra={extra} differing={bad}"
        )


def main(argv):
    if len(argv) != 3:
        print("usage: mkhplif.py OUTPUT.lif SRC_DIR", file=sys.stderr)
        return 1
    output, src = argv[1], argv[2]

    vol = LifVolume()
    expected = build_tree(vol, src)
    image = vol.build()
    verify_roundtrip(image, expected)

    with open(output, "wb") as f:
        f.write(image)
    print(f"mkhplif: wrote {output} ({len(expected)} files, {len(image)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
