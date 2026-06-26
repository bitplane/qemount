#!/usr/bin/env python3
"""mkrsdos - build a Tandy CoCo RS-DOS (Disk BASIC) filesystem image.

Usage: mkrsdos.py OUTPUT.dsk SRC_DIR

Packs the regular files under SRC_DIR into a fresh 35-track single-sided
RS-DOS disk image (the standard CoCo Disk BASIC layout). RS-DOS is flat (no
subdirectories), so the tree is flattened and names are sanitised to 8.3.

This is a test-fixture generator, not a reader: qemount defers filesystem
reading to the original system in an emulator. The image is verified by reading
the whole directory back, byte-for-byte, before it is written out.

Format reference: docs/format/fs/coco-rsdos.md
"""

import math
import os
import sys

# ---- Geometry ----

SECTOR = 256
SECTORS_PER_TRACK = 18
TRACKS = 35
IMAGE_SIZE = TRACKS * SECTORS_PER_TRACK * SECTOR  # 161280

SECTORS_PER_GRAN = 9
GRAN_BYTES = SECTORS_PER_GRAN * SECTOR  # 2304
TOTAL_GRANS = 68  # granules 0..67 (directory track carries no file data)

DIR_TRACK = 17
GRANULE_MAP_SECTOR = 2  # track 17, sector 2 (1-based)
DIR_FIRST_SECTOR = 3  # track 17, sectors 3..11
DIR_SECTORS = 9
ENTRIES_PER_SECTOR = 8
ENTRY_LEN = 32
MAX_ENTRIES = DIR_SECTORS * ENTRIES_PER_SECTOR  # 72

# ---- Granule map byte values ----

GRAN_FREE = 0xFF
GRAN_LAST_BASE = 0xC0  # + sectors used in the final granule (1..9)

# ---- Directory entry ----

DIR_END = 0xFF  # first byte: no more entries
FT_MACHINE = 0x02
FLAG_BINARY = 0x00


def sector_offset(track, sector):
    """Byte offset of a 1-based sector within a track."""
    return (track * SECTORS_PER_TRACK + (sector - 1)) * SECTOR


def gran_track(g):
    """Physical track holding granule g (track 17 is skipped)."""
    return g // 2 if g < 34 else g // 2 + 1


def gran_first_sector(g):
    """First 1-based sector of granule g within its track."""
    return 1 if g % 2 == 0 else 10


def gran_offset(g):
    return sector_offset(gran_track(g), gran_first_sector(g))


def rsdos_name(path):
    """Sanitise a filename to an 8.3 RS-DOS (name, ext) pair, uppercased."""
    base = os.path.basename(path)
    if "." in base:
        name, ext = base.rsplit(".", 1)
    else:
        name, ext = base, ""

    def clean(s, n):
        s = "".join(c for c in s.upper() if c.isalnum())
        return s[:n]

    name = clean(name, 8) or "FILE"
    ext = clean(ext, 3)
    return name, ext


class RsDos:
    def __init__(self):
        self.image = bytearray(IMAGE_SIZE)
        self.gran_map = [GRAN_FREE] * TOTAL_GRANS
        self.entries = []  # (name, ext, ftype, flag, first_gran, bytes_last_sector)

    # -- allocation --

    def _alloc_grans(self, count):
        free = [g for g in range(TOTAL_GRANS) if self.gran_map[g] == GRAN_FREE]
        if len(free) < count:
            raise ValueError(f"disk full: need {count} granules, {len(free)} free")
        return free[:count]

    def add_file(self, name, ext, data, ftype=FT_MACHINE, flag=FLAG_BINARY):
        if len(self.entries) >= MAX_ENTRIES:
            raise ValueError("directory full (72 entries)")

        nbytes = len(data)
        total_sectors = max(1, math.ceil(nbytes / SECTOR))
        total_grans = math.ceil(total_sectors / SECTORS_PER_GRAN)
        sectors_in_last = total_sectors - (total_grans - 1) * SECTORS_PER_GRAN
        bytes_last_sector = nbytes - (total_sectors - 1) * SECTOR  # 0..256

        chain = self._alloc_grans(total_grans)

        # Lay the data down one granule at a time (each granule is contiguous).
        pos = 0
        for g in chain:
            chunk = data[pos : pos + GRAN_BYTES]
            off = gran_offset(g)
            self.image[off : off + len(chunk)] = chunk
            pos += len(chunk)

        # Link the granule chain; final granule gets the 0xC0+sectors marker.
        for i, g in enumerate(chain[:-1]):
            self.gran_map[g] = chain[i + 1]
        self.gran_map[chain[-1]] = GRAN_LAST_BASE + sectors_in_last

        self.entries.append((name, ext, ftype, flag, chain[0], bytes_last_sector))

    # -- serialise --

    def build(self):
        # Granule map: track 17, sector 2.
        gm_off = sector_offset(DIR_TRACK, GRANULE_MAP_SECTOR)
        for g in range(TOTAL_GRANS):
            self.image[gm_off + g] = self.gran_map[g]

        # Directory: track 17, sectors 3..11. Unused entries start with 0xFF.
        dir_off = sector_offset(DIR_TRACK, DIR_FIRST_SECTOR)
        for i in range(MAX_ENTRIES):
            eoff = dir_off + i * ENTRY_LEN
            if i < len(self.entries):
                name, ext, ftype, flag, first_gran, blast = self.entries[i]
                entry = bytearray(ENTRY_LEN)
                entry[0:8] = name.ljust(8).encode("ascii")[:8]
                entry[8:11] = ext.ljust(3).encode("ascii")[:3]
                entry[11] = ftype
                entry[12] = flag
                entry[13] = first_gran
                entry[14] = (blast >> 8) & 0xFF  # big-endian
                entry[15] = blast & 0xFF
                # bytes 16..31 left zero
                self.image[eoff : eoff + ENTRY_LEN] = entry
            else:
                self.image[eoff] = DIR_END  # 0xFF terminator / unused
        return bytes(self.image)


# ---- Round-trip reader (self-test only) ----


def extract(image):
    """Walk the directory and granule chains; return {(name,ext): bytes}."""
    out = {}
    gm_off = sector_offset(DIR_TRACK, GRANULE_MAP_SECTOR)
    gran_map = list(image[gm_off : gm_off + TOTAL_GRANS])

    dir_off = sector_offset(DIR_TRACK, DIR_FIRST_SECTOR)
    for i in range(MAX_ENTRIES):
        eoff = dir_off + i * ENTRY_LEN
        first = image[eoff]
        if first == DIR_END:
            break
        if first == 0x00:  # deleted
            continue
        name = image[eoff : eoff + 8].decode("ascii").rstrip()
        ext = image[eoff + 8 : eoff + 11].decode("ascii").rstrip()
        first_gran = image[eoff + 13]
        blast = (image[eoff + 14] << 8) | image[eoff + 15]

        # Follow the granule chain.
        grans = []
        g = first_gran
        guard = 0
        while True:
            grans.append(g)
            val = gran_map[g]
            guard += 1
            if guard > TOTAL_GRANS:
                raise ValueError("granule chain loop")
            if val >= GRAN_LAST_BASE:  # 0xC0..0xC9 terminator (0xFF won't occur mid-chain)
                sectors_in_last = val - GRAN_LAST_BASE
                break
            g = val

        total_sectors = (len(grans) - 1) * SECTORS_PER_GRAN + sectors_in_last
        length = (total_sectors - 1) * SECTOR + blast

        data = bytearray()
        for g in grans:
            off = gran_offset(g)
            data += image[off : off + GRAN_BYTES]
        out[(name, ext)] = bytes(data[:length])
    return out


def build_tree(disk, src):
    """Flatten regular files under src into the disk, skipping symlinks."""
    expected = {}
    used = set()
    for root, _dirs, files in sorted(os.walk(src)):
        for fname in sorted(files):
            path = os.path.join(root, fname)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            name, ext = rsdos_name(path)
            # Resolve 8.3 collisions deterministically.
            key = (name, ext)
            n = 1
            while key in used:
                suffix = str(n)
                key = (name[: 8 - len(suffix)] + suffix, ext)
                n += 1
            used.add(key)
            with open(path, "rb") as f:
                data = f.read()
            disk.add_file(key[0], key[1], data)
            expected[key] = data
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
        print("usage: mkrsdos.py OUTPUT.dsk SRC_DIR", file=sys.stderr)
        return 1
    output, src = argv[1], argv[2]

    disk = RsDos()
    expected = build_tree(disk, src)
    image = disk.build()
    verify_roundtrip(image, expected)

    with open(output, "wb") as f:
        f.write(image)
    print(f"mkrsdos: wrote {output} ({len(expected)} files, {len(image)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
