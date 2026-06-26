#!/usr/bin/env python3
"""mkataridos - create and read Atari DOS 2.0S / 2.5 disk images.

A from-scratch formatter for the Atari 8-bit "Atari DOS 2" filesystem, the
disk layout of the 400/800/XL/XE machines. Supports single density (DOS 2.0S,
720 x 128-byte sectors) and enhanced density (DOS 2.5, 1040 x 128-byte sectors
with the second VTOC at sector 1024). Output is a raw sector image or an ATR
container, chosen by the output extension.

Usage:
  mkataridos.py create [--density sd|ed] OUTPUT SRC_DIR   # pack a directory
  mkataridos.py list   IMAGE                              # list the directory
  mkataridos.py extract IMAGE DEST_DIR                    # unpack files

OUTPUT ending in .atr is wrapped in a 16-byte ATR header; any other extension
(.xfd, .dsk, .raw, ...) is a bare sector dump.

The filesystem is flat (no subdirectories), names are 8.3, and disks are data
disks (non-bootable; no DOS.SYS is written). `create` verifies every image by
reading the whole directory back, byte-for-byte, before writing it out.

Format reference: De Re Atari ch.9; layout cross-checked against the working
implementation jhallen/atari-tools. This tool is dependency-free and standalone.
"""

import argparse
import math
import os
import sys

# ---- Geometry ----

SECTOR_SIZE = 128
SD_SECTORS = 720
ED_SECTORS = 1040
ED_USABLE = 1024  # 10-bit forward pointer ceiling (sectors 1025-1040 unreachable)

DATA_BYTES = 125  # usable data bytes per 128-byte sector (3-byte footer)
FOOT_FILE_NEXT_HI = 125  # file_no<<2 | (next>>8 & 3)
FOOT_NEXT_LO = 126
FOOT_COUNT = 127

VTOC_SECTOR = 360
DIR_SECTOR = 361
DIR_SECTORS = 8
ENTRIES_PER_SECTOR = 8
MAX_FILES = DIR_SECTORS * ENTRIES_PER_SECTOR  # 64

VTOC2_SECTOR = 1024
VTOC_BITMAP_OFF = 10  # bitmap for sectors 0-719 at VTOC bytes 10-99
SD_BITMAP_BYTES = 90  # sectors 0-719
ED_BITMAP_BYTES = 128  # sectors 0-1023
ED_VTOC2_COPY_FROM = 6  # vtoc2[0:122] = bitmap[6:128]
VTOC2_FREE_ABOVE = 122  # free-sector count above sector 719 (LE)

# Directory entry flag: in-use (0x40) | DOS2 (0x02).
DIR_FLAG_INUSE_DOS2 = 0x42

# ATR container header.
ATR_MAGIC = 0x0296
ATR_HEADER = 16


def free_sectors_total(density):
    return 707 if density == "sd" else 1010


class AtariDosDisk:
    """An Atari DOS 2 volume held as an in-memory sector image."""

    def __init__(self, density="sd"):
        if density not in ("sd", "ed"):
            raise ValueError("density must be 'sd' or 'ed'")
        self.density = density
        self.total_sectors = SD_SECTORS if density == "sd" else ED_SECTORS
        self.usable = SD_SECTORS if density == "sd" else ED_USABLE
        self.image = bytearray(self.total_sectors * SECTOR_SIZE)
        # bitmap: 1 bit per sector, 1 = free. Covers sectors 0..(usable-1).
        nbits = SD_SECTORS if density == "sd" else ED_USABLE
        self.bitmap = bytearray(nbits // 8)  # 90 (SD) or 128 (ED) bytes
        for b in range(len(self.bitmap)):
            self.bitmap[b] = 0xFF  # all free
        self.entries = []  # (name, ext, start_sector, sector_count)

        # Reserve the structural sectors.
        for s in (0, 1, 2, 3, VTOC_SECTOR):
            self._mark_used(s)
        for s in range(DIR_SECTOR, DIR_SECTOR + DIR_SECTORS):
            self._mark_used(s)
        if density == "ed":
            self._mark_used(720)  # reserved by DOS 2.5

    # -- bitmap --

    def _is_free(self, sector):
        return bool(self.bitmap[sector >> 3] & (1 << (7 - (sector & 7))))

    def _mark_used(self, sector):
        self.bitmap[sector >> 3] &= ~(1 << (7 - (sector & 7))) & 0xFF

    def _free_count(self):
        return sum(bin(b).count("1") for b in self.bitmap)

    def _alloc(self):
        for sector in range(self.usable):
            if self._is_free(sector):
                self._mark_used(sector)
                return sector
        raise ValueError("disk full")

    def _sector_off(self, sector):
        return (sector - 1) * SECTOR_SIZE

    # -- files --

    def add_file(self, name, ext, data):
        file_no = len(self.entries)
        if file_no >= MAX_FILES:
            raise ValueError("directory full (64 files)")

        n = len(data)
        nsec = max(1, math.ceil(n / DATA_BYTES))
        chain = [self._alloc() for _ in range(nsec)]

        for i, sector in enumerate(chain):
            off = self._sector_off(sector)
            chunk = data[i * DATA_BYTES : (i + 1) * DATA_BYTES]
            self.image[off : off + len(chunk)] = chunk
            nxt = chain[i + 1] if i + 1 < len(chain) else 0
            self.image[off + FOOT_FILE_NEXT_HI] = (file_no << 2) | ((nxt >> 8) & 0x03)
            self.image[off + FOOT_NEXT_LO] = nxt & 0xFF
            self.image[off + FOOT_COUNT] = len(chunk)

        self.entries.append((name, ext, chain[0], nsec))

    # -- serialise --

    def _write_directory(self):
        for k, (name, ext, start, count) in enumerate(self.entries):
            sector = DIR_SECTOR + k // ENTRIES_PER_SECTOR
            off = self._sector_off(sector) + (k % ENTRIES_PER_SECTOR) * 16
            self.image[off + 0] = DIR_FLAG_INUSE_DOS2
            self.image[off + 1] = count & 0xFF
            self.image[off + 2] = (count >> 8) & 0xFF
            self.image[off + 3] = start & 0xFF
            self.image[off + 4] = (start >> 8) & 0xFF
            self.image[off + 5 : off + 13] = name.ljust(8).encode("ascii")[:8]
            self.image[off + 13 : off + 16] = ext.ljust(3).encode("ascii")[:3]

    def _write_vtoc(self):
        vo = self._sector_off(VTOC_SECTOR)
        self.image[vo + 0] = 0x02  # DOS code
        total = free_sectors_total(self.density)
        self.image[vo + 1] = total & 0xFF
        self.image[vo + 2] = (total >> 8) & 0xFF
        free = self._free_count()
        self.image[vo + 3] = free & 0xFF
        self.image[vo + 4] = (free >> 8) & 0xFF
        # Bitmap for sectors 0-719 (first 90 bytes of the bitmap).
        self.image[vo + VTOC_BITMAP_OFF : vo + VTOC_BITMAP_OFF + SD_BITMAP_BYTES] = (
            self.bitmap[:SD_BITMAP_BYTES]
        )

        if self.density == "ed":
            v2 = self._sector_off(VTOC2_SECTOR)
            # vtoc2[0:122] = bitmap[6:128]  (sectors 48-1023)
            self.image[v2 : v2 + (ED_BITMAP_BYTES - ED_VTOC2_COPY_FROM)] = (
                self.bitmap[ED_VTOC2_COPY_FROM:ED_BITMAP_BYTES]
            )
            above = sum(
                bin(b).count("1") for b in self.bitmap[SD_BITMAP_BYTES:ED_BITMAP_BYTES]
            )
            self.image[v2 + VTOC2_FREE_ABOVE] = above & 0xFF
            self.image[v2 + VTOC2_FREE_ABOVE + 1] = (above >> 8) & 0xFF

    def to_raw(self):
        self._write_directory()
        self._write_vtoc()
        return bytes(self.image)

    def to_atr(self):
        raw = self.to_raw()
        paragraphs = len(raw) // 16
        hdr = bytearray(ATR_HEADER)
        hdr[0] = ATR_MAGIC & 0xFF
        hdr[1] = (ATR_MAGIC >> 8) & 0xFF
        hdr[2] = paragraphs & 0xFF
        hdr[3] = (paragraphs >> 8) & 0xFF
        hdr[4] = SECTOR_SIZE & 0xFF
        hdr[5] = (SECTOR_SIZE >> 8) & 0xFF
        hdr[6] = (paragraphs >> 16) & 0xFF
        hdr[7] = (paragraphs >> 24) & 0xFF
        return bytes(hdr) + raw


# ---- Reader (round-trip self-test, and the list/extract subcommands) ----


def _load_image(path):
    """Return (raw_sector_bytes, density) from a raw or ATR file."""
    with open(path, "rb") as f:
        blob = f.read()
    if len(blob) >= ATR_HEADER and (blob[0] | (blob[1] << 8)) == ATR_MAGIC:
        blob = blob[ATR_HEADER:]
    nsec = len(blob) // SECTOR_SIZE
    density = "ed" if nsec > SD_SECTORS else "sd"
    return blob, density


def extract_image(raw):
    """Walk the directory and sector chains; return [(name, ext, bytes), ...]."""
    out = []
    for k in range(MAX_FILES):
        sector = DIR_SECTOR + k // ENTRIES_PER_SECTOR
        off = (sector - 1) * SECTOR_SIZE + (k % ENTRIES_PER_SECTOR) * 16
        flag = raw[off]
        if flag == 0x00:
            continue  # never-used slot
        if not (flag & 0x40):
            continue  # not in use (deleted / open)
        name = raw[off + 5 : off + 13].decode("ascii").rstrip()
        ext = raw[off + 13 : off + 16].decode("ascii").rstrip()
        start = raw[off + 3] | (raw[off + 4] << 8)

        data = bytearray()
        sector = start
        guard = 0
        while sector:
            so = (sector - 1) * SECTOR_SIZE
            file_no = (raw[so + FOOT_FILE_NEXT_HI] >> 2) & 0x3F
            if file_no != k:
                raise ValueError(
                    f"sector {sector}: file_no {file_no} != dir slot {k}"
                )
            count = raw[so + FOOT_COUNT]
            data += raw[so : so + count]
            sector = ((raw[so + FOOT_FILE_NEXT_HI] & 0x03) << 8) | raw[so + FOOT_NEXT_LO]
            guard += 1
            if guard > ED_SECTORS:
                raise ValueError("sector chain loop")
        out.append((name, ext, bytes(data)))
    return out


# ---- Directory packing ----


def atari_name(path):
    base = os.path.basename(path)
    name, ext = (base.rsplit(".", 1) + [""])[:2] if "." in base else (base, "")

    def clean(s, n):
        return "".join(c for c in s.upper() if c.isalnum())[:n]

    return clean(name, 8) or "FILE", clean(ext, 3)


def build_tree(disk, src):
    expected = []
    used = set()
    for root, _dirs, files in sorted(os.walk(src)):
        for fname in sorted(files):
            path = os.path.join(root, fname)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            name, ext = atari_name(path)
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
            expected.append((key[0], key[1], data))
    return expected


def verify_roundtrip(raw, expected):
    got = extract_image(raw)
    exp = [(n, e, d) for (n, e, d) in expected]
    if got != exp:
        raise SystemExit(f"round-trip mismatch:\n expected={[(n,e,len(d)) for n,e,d in exp]}\n got={[(n,e,len(d)) for n,e,d in got]}")


# ---- CLI ----


def cmd_create(args):
    disk = AtariDosDisk(args.density)
    expected = build_tree(disk, args.src_dir)
    raw = disk.to_raw()
    verify_roundtrip(raw, expected)

    if args.output.lower().endswith(".atr"):
        blob = disk.to_atr()
        kind = "ATR"
    else:
        blob = raw
        kind = "raw"
    with open(args.output, "wb") as f:
        f.write(blob)
    print(
        f"mkataridos: wrote {args.output} "
        f"({args.density.upper()} {kind}, {len(expected)} files, {len(blob)} bytes)"
    )
    return 0


def cmd_list(args):
    raw, density = _load_image(args.image)
    print(f"{args.image}: Atari DOS {density.upper()}")
    for name, ext, data in extract_image(raw):
        label = f"{name}.{ext}" if ext else name
        print(f"  {label:<13} {len(data):>7} bytes")
    return 0


def cmd_extract(args):
    raw, _ = _load_image(args.image)
    os.makedirs(args.dest_dir, exist_ok=True)
    for name, ext, data in extract_image(raw):
        fname = f"{name}.{ext}" if ext else name
        with open(os.path.join(args.dest_dir, fname), "wb") as f:
            f.write(data)
        print(f"  {fname} ({len(data)} bytes)")
    return 0


def main(argv):
    p = argparse.ArgumentParser(prog="mkataridos", description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("create", help="pack a directory into a disk image")
    c.add_argument("--density", choices=("sd", "ed"), default="sd")
    c.add_argument("output")
    c.add_argument("src_dir")
    c.set_defaults(func=cmd_create)

    ls = sub.add_parser("list", help="list a disk image's directory")
    ls.add_argument("image")
    ls.set_defaults(func=cmd_list)

    ex = sub.add_parser("extract", help="extract files from a disk image")
    ex.add_argument("image")
    ex.add_argument("dest_dir")
    ex.set_defaults(func=cmd_extract)

    args = p.parse_args(argv[1:])
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
