#!/usr/bin/env python3
"""mkvtech - build a VTech VZ-DOS (Laser 200/210/310, Dick Smith VZ-200/300)
filesystem image.

Usage: mkvtech.py OUTPUT.dsk SRC_DIR

Packs the regular files under SRC_DIR into a fresh 40-track single-sided VZ-DOS
disk (the logical 128-byte-sector layout the filesystem itself uses, 80 KB).
VZ-DOS is flat (no subdirectories), so the tree is flattened and names are
sanitised to 8 characters.

This is a test-fixture generator, not a reader: qemount defers filesystem
reading to the original system in an emulator. The image is verified by reading
the whole directory back, byte-for-byte, before it is written out.

Layout per MAME's fs_vtech.cpp; see docs/format/fs/vtech.md.
"""

import math
import os
import sys

# ---- Geometry (the logical 128-byte-sector filesystem layout) ----

SECTOR = 128
SECTORS_PER_TRACK = 16
TRACKS = 40
IMAGE_SIZE = TRACKS * SECTORS_PER_TRACK * SECTOR  # 81920

DIR_TRACK = 0
DIR_SECTORS = 15  # track 0 sectors 0..14
BITMAP_SECTOR = 15  # track 0 sector 15
DATA_TRACK_START = 1  # tracks 1..39 hold file data

ENTRY_LEN = 16
ENTRIES_PER_SECTOR = SECTOR // ENTRY_LEN  # 8
MAX_ENTRIES = DIR_SECTORS * ENTRIES_PER_SECTOR  # 120

DATA_PER_SECTOR = 126  # bytes 0..125; bytes 126,127 are the next-sector link
LINK_TRACK = 126
LINK_SECTOR = 127

TYPE_END = 0x00
TYPE_DELETED = 0x01
TYPE_BINARY = ord("B")  # 0x42 - raw byte payload
SEP = 0x3A  # ':'
LOAD_BASE = 0x7000  # arbitrary load address; only end-start matters


def sector_offset(track, sector):
    return (track * SECTORS_PER_TRACK + sector) * SECTOR


def vz_name(path):
    """Sanitise a filename to an 8-char uppercase VZ name (no extension field)."""
    stem = os.path.basename(path)
    if "." in stem:
        stem = stem.rsplit(".", 1)[0]
    stem = "".join(c for c in stem.upper() if c.isalnum())
    return (stem or "FILE")[:8]


class VzDos:
    def __init__(self):
        self.image = bytearray(IMAGE_SIZE)
        # bitmap[(track-1)*2 + sector//8], bit 1<<(sector&7); set = allocated.
        self.bitmap = bytearray((TRACKS - 1) * 2)  # tracks 1..39 -> 78 bytes
        self.entries = []  # (name, first_track, first_sector, start, end)

    def _is_free(self, track, sector):
        b = (track - 1) * 2 + sector // 8
        return not (self.bitmap[b] & (1 << (sector & 7)))

    def _mark(self, track, sector):
        b = (track - 1) * 2 + sector // 8
        self.bitmap[b] |= 1 << (sector & 7)

    def _alloc(self):
        for track in range(DATA_TRACK_START, TRACKS):
            for sector in range(SECTORS_PER_TRACK):
                if self._is_free(track, sector):
                    self._mark(track, sector)
                    return (track, sector)
        raise ValueError("disk full")

    def add_file(self, name, data, ftype=TYPE_BINARY):
        if len(self.entries) >= MAX_ENTRIES:
            raise ValueError("directory full (120 entries)")

        n = len(data)
        nsectors = max(1, math.ceil(n / DATA_PER_SECTOR))
        chain = [self._alloc() for _ in range(nsectors)]

        for i, (track, sector) in enumerate(chain):
            off = sector_offset(track, sector)
            chunk = data[i * DATA_PER_SECTOR : (i + 1) * DATA_PER_SECTOR]
            self.image[off : off + len(chunk)] = chunk
            nxt = chain[i + 1] if i + 1 < len(chain) else (0, 0)
            self.image[off + LINK_TRACK] = nxt[0]
            self.image[off + LINK_SECTOR] = nxt[1]

        start = LOAD_BASE
        end = (LOAD_BASE + n) & 0xFFFF  # length = (end - start) & 0xFFFF
        self.entries.append((name, chain[0][0], chain[0][1], start, end))

    def build(self):
        for k, (name, ftrack, fsector, start, end) in enumerate(self.entries):
            sector = k // ENTRIES_PER_SECTOR
            slot = k % ENTRIES_PER_SECTOR
            off = sector_offset(DIR_TRACK, sector) + slot * ENTRY_LEN
            e = bytearray(ENTRY_LEN)
            e[0] = TYPE_BINARY
            e[1] = SEP
            e[2:10] = name.ljust(8).encode("ascii")[:8]
            e[0xA] = ftrack
            e[0xB] = fsector
            e[0xC] = start & 0xFF
            e[0xD] = (start >> 8) & 0xFF
            e[0xE] = end & 0xFF
            e[0xF] = (end >> 8) & 0xFF
            self.image[off : off + ENTRY_LEN] = e
        # The next slot is zero-filled -> type 0x00 terminates the directory.

        bm = sector_offset(DIR_TRACK, BITMAP_SECTOR)
        self.image[bm : bm + len(self.bitmap)] = self.bitmap
        return bytes(self.image)


# ---- Round-trip reader (self-test only) ----


def extract(image):
    out = {}
    for k in range(MAX_ENTRIES):
        sector = k // ENTRIES_PER_SECTOR
        slot = k % ENTRIES_PER_SECTOR
        off = sector_offset(DIR_TRACK, sector) + slot * ENTRY_LEN
        ftype = image[off]
        if ftype == TYPE_END:
            break
        if ftype == TYPE_DELETED:
            continue
        name = image[off + 2 : off + 10].decode("ascii").rstrip()
        track = image[off + 0xA]
        sec = image[off + 0xB]
        start = image[off + 0xC] | (image[off + 0xD] << 8)
        end = image[off + 0xE] | (image[off + 0xF] << 8)
        length = (end - start) & 0xFFFF

        data = bytearray()
        guard = 0
        while len(data) < length:
            doff = sector_offset(track, sec)
            take = min(DATA_PER_SECTOR, length - len(data))
            data += image[doff : doff + take]
            track = image[doff + LINK_TRACK]
            sec = image[doff + LINK_SECTOR]
            guard += 1
            if guard > TRACKS * SECTORS_PER_TRACK:
                raise ValueError("sector chain loop")
        out[name] = bytes(data)
    return out


def build_tree(disk, src):
    expected = {}
    used = set()
    for root, _dirs, files in sorted(os.walk(src)):
        for fname in sorted(files):
            path = os.path.join(root, fname)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            name = vz_name(path)
            n = 1
            while name in used:
                suffix = str(n)
                name = vz_name(path)[: 8 - len(suffix)] + suffix
                n += 1
            used.add(name)
            with open(path, "rb") as f:
                data = f.read()
            disk.add_file(name, data)
            expected[name] = data
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
        print("usage: mkvtech.py OUTPUT.dsk SRC_DIR", file=sys.stderr)
        return 1
    output, src = argv[1], argv[2]

    disk = VzDos()
    expected = build_tree(disk, src)
    image = disk.build()
    verify_roundtrip(image, expected)

    with open(output, "wb") as f:
        f.write(image)
    print(f"mkvtech: wrote {output} ({len(expected)} files, {len(image)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
