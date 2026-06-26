#!/usr/bin/env python3
"""mkoricjasmin - build an Oric Jasmin (FT-DOS) filesystem image.

Usage: mkoricjasmin.py OUTPUT.dsk SRC_DIR

Packs the regular files under SRC_DIR into a fresh single-sided Oric Jasmin
disk (41 tracks x 17 sectors x 256 bytes). The filesystem is flat (no
subdirectories), so the tree is flattened and names are sanitised to 8.3.

This is a test-fixture generator, not a reader: qemount defers filesystem
reading to the original system in an emulator. The image is verified by reading
the whole directory back, byte-for-byte, before it is written out.

Layout per MAME's fs_oric_jasmin.cpp; see docs/format/fs/oric-jasmin.md.

NOTE: the format is mixed-endian. Track/sector ("cs") references are big-endian
(byte0=track, byte1=sector); numeric fields (load address, length, sector count,
directory header words) are little-endian.
"""

import math
import os
import struct
import sys

# ---- Geometry ----

SECTOR = 256
SECTORS_PER_TRACK = 17
TRACKS = 41
HEADS = 1
TOTAL_BLOCKS = TRACKS * SECTORS_PER_TRACK  # 697
IMAGE_SIZE = TOTAL_BLOCKS * SECTOR  # 178432

VOLUME_TRACK = 20
BITMAP_BLOCK = VOLUME_TRACK * SECTORS_PER_TRACK  # 340 (track 20 sector 1)
DIR_BLOCK = BITMAP_BLOCK + 1  # 341 (track 20 sector 2)

# ---- Directory ----

DIR_ENTRY_BASE = 0x04
DIR_ENTRY_LEN = 0x12  # 18 bytes
DIR_ENTRIES = 14  # per sector (0x04 + 14*18 = 0x100)

LOCK_UNLOCKED = ord("U")
FILE_TYPE_SEQ = ord("S")

# ---- Inode ----

INODE_LOAD_ADDR = 0x0501  # arbitrary Oric load address; only length matters
INODE_END = 0xFF00  # next-inode marker on the last inode
REF_END = 0xFFFF  # end of data-ref list / invalid ref
MAX_DATA_REFS = 125  # (256 - 6) / 2 refs per inode sector

# ---- Volume sector ----

SIG_OFF = 0xF6
VOLNAME_OFF = 0xF8
VOLNAME = "QMOUNT"


def block_to_cs(block):
    """block -> 16-bit (track<<8)|sector reference (sector is 1-based)."""
    track, idx = divmod(block, SECTORS_PER_TRACK)
    return (track << 8) | (idx + 1)


def cs_to_block(ref):
    track = ref >> 8
    sector = ref & 0xFF
    return track * SECTORS_PER_TRACK + sector - 1


def ref_valid(ref):
    sector = ref & 0xFF
    track = ref >> 8
    return 1 <= sector <= SECTORS_PER_TRACK and track < TRACKS


def oric_name(path):
    """Sanitise to an (name<=8, ext<=3) uppercase 8.3 pair."""
    base = os.path.basename(path)
    if "." in base:
        name, ext = base.rsplit(".", 1)
    else:
        name, ext = base, ""

    def clean(s, n):
        return "".join(c for c in s.upper() if c.isalnum())[:n]

    return (clean(name, 8) or "FILE", clean(ext, 3))


class VolumeImage:
    def __init__(self, volname=VOLNAME):
        self.image = bytearray(IMAGE_SIZE)
        self.volname = volname
        # bitmap[track] = 24-bit value, bit (17-sector) set => free.
        self.bitmap = [0x1FFFF] * TRACKS
        self.entries = []  # (name, ext, first_inode_ref, sector_count)
        # Reserve the volume sector and the directory sector.
        self._mark_used(BITMAP_BLOCK)
        self._mark_used(DIR_BLOCK)

    # -- bitmap / allocation --

    def _bit(self, block):
        track, idx = divmod(block, SECTORS_PER_TRACK)
        sector = idx + 1
        return track, 17 - sector

    def _is_free(self, block):
        track, bit = self._bit(block)
        return bool(self.bitmap[track] & (1 << bit))

    def _mark_used(self, block):
        track, bit = self._bit(block)
        self.bitmap[track] &= ~(1 << bit) & 0xFFFFFF

    def _alloc(self):
        for block in range(TOTAL_BLOCKS):
            if self._is_free(block):
                self._mark_used(block)
                return block
        raise ValueError("disk full")

    def _sector(self, block):
        return block * SECTOR

    # -- files --

    def add_file(self, name, ext, data):
        if len(self.entries) >= DIR_ENTRIES:
            raise ValueError("directory full (14 entries)")

        n = len(data)
        ndata = max(1, math.ceil(n / SECTOR))
        if ndata > MAX_DATA_REFS:
            raise ValueError("file too large for a single inode sector")

        inode_block = self._alloc()
        data_blocks = [self._alloc() for _ in range(ndata)]

        # Lay the data down.
        for i, blk in enumerate(data_blocks):
            off = self._sector(blk)
            chunk = data[i * SECTOR : (i + 1) * SECTOR]
            self.image[off : off + len(chunk)] = chunk

        # Write the inode sector.
        io = self._sector(inode_block)
        struct.pack_into(">H", self.image, io + 0, INODE_END)  # big-endian
        struct.pack_into("<H", self.image, io + 2, INODE_LOAD_ADDR)  # little
        struct.pack_into("<H", self.image, io + 4, n)  # little (byte-exact len)
        pos = 6
        for blk in data_blocks:
            struct.pack_into(">H", self.image, io + pos, block_to_cs(blk))
            pos += 2
        struct.pack_into(">H", self.image, io + pos, REF_END)

        sector_count = 1 + ndata  # inode + data sectors
        self.entries.append((name, ext, block_to_cs(inode_block), sector_count))

    # -- serialise --

    def build(self):
        # Directory sector header: self=0, next=0 (single dir sector).
        do = self._sector(DIR_BLOCK)
        struct.pack_into("<H", self.image, do + 0, 0x0000)
        struct.pack_into("<H", self.image, do + 2, 0x0000)
        for k, (name, ext, inode_ref, scount) in enumerate(self.entries):
            off = do + DIR_ENTRY_BASE + k * DIR_ENTRY_LEN
            struct.pack_into(">H", self.image, off + 0x00, inode_ref)  # big
            self.image[off + 0x02] = LOCK_UNLOCKED
            fname = name.ljust(8)[:8] + "." + ext.ljust(3)[:3]  # 12 bytes
            self.image[off + 0x03 : off + 0x0F] = fname.encode("ascii")
            self.image[off + 0x0F] = FILE_TYPE_SEQ
            struct.pack_into("<H", self.image, off + 0x10, scount)  # little

        # Volume / bitmap sector.
        vo = self._sector(BITMAP_BLOCK)
        for track in range(TRACKS):
            b = self.bitmap[track]
            self.image[vo + 3 * track + 0] = b & 0xFF
            self.image[vo + 3 * track + 1] = (b >> 8) & 0xFF
            self.image[vo + 3 * track + 2] = (b >> 16) & 0xFF
        self.image[vo + SIG_OFF] = 0x80
        self.image[vo + SIG_OFF + 1] = 0x80
        self.image[vo + VOLNAME_OFF : vo + VOLNAME_OFF + 8] = (
            self.volname.ljust(8).encode("ascii")[:8]
        )
        return bytes(self.image)


# ---- Round-trip reader (self-test only) ----


def extract(image):
    out = {}
    do = DIR_BLOCK * SECTOR
    for k in range(DIR_ENTRIES):
        off = do + DIR_ENTRY_BASE + k * DIR_ENTRY_LEN
        (inode_ref,) = struct.unpack_from(">H", image, off + 0x00)
        if not ref_valid(inode_ref):
            continue
        fname = image[off + 0x03 : off + 0x0F].decode("ascii")
        name = fname[:8].rstrip()
        ext = fname[9:12].rstrip()
        key = name + ("." + ext if ext else "")

        # Walk the inode chain, collecting data sector refs.
        length = None
        data_refs = []
        ref = inode_ref
        guard = 0
        while True:
            io = cs_to_block(ref) * SECTOR
            (nxt,) = struct.unpack_from(">H", image, io + 0)
            if length is None:
                (length,) = struct.unpack_from("<H", image, io + 4)
            pos = 6
            while True:
                (dref,) = struct.unpack_from(">H", image, io + pos)
                if dref == REF_END:
                    break
                data_refs.append(dref)
                pos += 2
            if nxt == INODE_END:
                break
            ref = nxt
            guard += 1
            if guard > TOTAL_BLOCKS:
                raise ValueError("inode chain loop")

        data = bytearray()
        for dref in data_refs:
            dio = cs_to_block(dref) * SECTOR
            data += image[dio : dio + SECTOR]
        out[key] = bytes(data[:length])
    return out


def build_tree(vol, src):
    expected = {}
    used = set()
    for root, _dirs, files in sorted(os.walk(src)):
        for fname in sorted(files):
            path = os.path.join(root, fname)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            name, ext = oric_name(path)
            key = name + ("." + ext if ext else "")
            n = 1
            while key in used:
                suffix = str(n)
                name = (name[: 8 - len(suffix)] + suffix)
                key = name + ("." + ext if ext else "")
                n += 1
            used.add(key)
            with open(path, "rb") as f:
                data = f.read()
            vol.add_file(name, ext, data)
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
        print("usage: mkoricjasmin.py OUTPUT.dsk SRC_DIR", file=sys.stderr)
        return 1
    output, src = argv[1], argv[2]

    vol = VolumeImage()
    expected = build_tree(vol, src)
    image = vol.build()
    verify_roundtrip(image, expected)

    with open(output, "wb") as f:
        f.write(image)
    print(f"mkoricjasmin: wrote {output} ({len(expected)} files, {len(image)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
