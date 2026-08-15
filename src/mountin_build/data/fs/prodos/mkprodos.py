#!/usr/bin/env python3
"""
Apple ProDOS filesystem image creator — an mkfs for ProDOS.

Formats a blank 800K (1600 x 512-byte block) ProDOS volume and packs a host
directory tree into it, preserving subdirectories. Output is a *plain*
ProDOS-order block image (the raw volume), suitable for wrapping in a 2IMG /
ProDOS-order .po container (a separate disk-image-layer step).

Layout of a fresh volume (see docs/format/fs/prodos.md):

    block size        512 bytes
    blocks 0..1       boot loader (left zero)
    blocks 2..5       volume directory (4 blocks, chained 2->3->4->5)
    block  6          volume bitmap (1 bit/block, 1 = free, high bit = low block)
    blocks 7..1599    data / subdirectories

Directories are chains of 512-byte blocks; each block holds a 4-byte
prev/next-pointer pair followed by thirteen 39-byte ($27) entries. Entry 0 of a
directory's *key* block is a header (volume header in the root, subdirectory
header in a subdir); the remaining slots hold file and subdirectory entries.
Files come in three sizes by storage type: seedling (<=512 B, the key block is
the data), sapling (<=128 KB, the key block is an index of 256 block pointers
stored split-byte — low halves then high halves), and tree (>128 KB, not
emitted here).

Usage:
    mkprodos.py OUTPUT.po SRC_DIR

Every regular file under SRC_DIR becomes a ProDOS file; every directory becomes
a real ProDOS subdirectory. Host names are sanitised to ProDOS rules (<=15
chars, A-Z/0-9/'.', leading letter). Dates are written as zero for reproducible
builds. The writer verifies the image by reading the whole tree back and
comparing it byte-for-byte before writing it out.

This tool is filesystem-layer only.
"""

import sys
from pathlib import Path

# ---- ProDOS geometry / constants ----
BLOCK = 512
TOTAL_BLOCKS = 1600                      # 800K Apple 3.5" volume

VOLDIR_START = 2                         # volume directory key block
VOLDIR_BLOCKS = 4                        # blocks 2..5 (fixed-size root)
BITMAP_BLOCK = 6                         # volume bitmap starts here

ENTRY_BASE = 0x04                        # first entry offset within a dir block
ENTRY_LEN = 0x27                         # 39 bytes
ENTRIES_PER_BLOCK = 0x0D                 # 13

# storage types (high nibble of byte 0 of an entry)
ST_SEEDLING = 0x1
ST_SAPLING = 0x2
ST_TREE = 0x3
ST_SUBDIR = 0xD
ST_SUBDIR_HEADER = 0xE
ST_VOL_HEADER = 0xF

# file types
FT_TXT = 0x04
FT_BIN = 0x06
FT_DIR = 0x0F

ACCESS = 0xC3                            # destroy + rename + write + read
SUBDIR_MARKER = 0x75                     # required byte at +0x10 of a subdir header

SEEDLING_MAX = 512
SAPLING_MAX = 0x20000                    # 128 KB

MAX_NAME = 15


def bitmap_blocks(total: int) -> int:
    return (total + 4095) // 4096


def prodos_name(host_name: str) -> str:
    """Sanitise a host name to ProDOS rules: <=15 chars, A-Z/0-9/'.', leading
    letter. Illegal characters collapse to '.'; runs of '.' are squeezed."""
    out = []
    for ch in host_name.upper():
        out.append(ch if (ch.isalnum() and ch.isascii()) or ch == "." else ".")
    name = "".join(out)
    while ".." in name:
        name = name.replace("..", ".")
    name = name.strip(".")
    if not name or not name[0].isalpha():
        name = "A" + name
    name = name[:MAX_NAME]
    if not name:
        raise ValueError(f"cannot derive a ProDOS name from {host_name!r}")
    return name


def file_type_for(name: str) -> int:
    return FT_TXT if name.upper().endswith(".TXT") else FT_BIN


class Volume:
    """A ProDOS volume image with a bitmap-backed block allocator."""

    def __init__(self, name: str, total: int = TOTAL_BLOCKS):
        self.total = total
        self.img = bytearray(total * BLOCK)
        self.bmap_blocks = bitmap_blocks(total)
        self.first_data = BITMAP_BLOCK + self.bmap_blocks
        self._init_bitmap()
        self._init_voldir(prodos_name(name))

    # ---- raw helpers ----
    def w(self, off: int, data: bytes) -> None:
        self.img[off:off + len(data)] = data

    def w16(self, off: int, value: int) -> None:
        self.img[off:off + 2] = value.to_bytes(2, "little")

    # ---- bitmap ----
    def _init_bitmap(self) -> None:
        base = BITMAP_BLOCK * BLOCK
        for b in range(self.total):          # every real block starts free (bit=1)
            self.img[base + b // 8] |= 0x80 >> (b % 8)
        for b in range(self.first_data):     # boot, voldir and bitmap are in use
            self._mark_used(b)

    def _mark_used(self, b: int) -> None:
        base = BITMAP_BLOCK * BLOCK
        self.img[base + b // 8] &= ~(0x80 >> (b % 8)) & 0xFF

    def _is_free(self, b: int) -> bool:
        base = BITMAP_BLOCK * BLOCK
        return bool((self.img[base + b // 8] >> (7 - b % 8)) & 1)

    def alloc_block(self) -> int:
        for b in range(self.first_data, self.total):
            if self._is_free(b):
                self._mark_used(b)
                return b
        raise ValueError("volume full: no free blocks")

    # ---- volume directory ----
    def _init_voldir(self, name: str) -> None:
        chain = [VOLDIR_START + i for i in range(VOLDIR_BLOCKS)]
        for i, blk in enumerate(chain):
            prev = chain[i - 1] if i > 0 else 0
            nxt = chain[i + 1] if i < len(chain) - 1 else 0
            self.w16(blk * BLOCK + 0, prev)
            self.w16(blk * BLOCK + 2, nxt)
        off = VOLDIR_START * BLOCK + ENTRY_BASE
        self.img[off + 0x00] = (ST_VOL_HEADER << 4) | len(name)
        self.w(off + 0x01, name.encode("ascii").ljust(MAX_NAME, b"\x00"))
        # 0x14..0x1B reserved, 0x1C creation date/time: left zero
        self.img[off + 0x1E] = ACCESS
        self.img[off + 0x1F] = ENTRY_LEN
        self.img[off + 0x20] = ENTRIES_PER_BLOCK
        # 0x21 file_count: maintained by Directory
        self.w16(off + 0x23, BITMAP_BLOCK)
        self.w16(off + 0x25, self.total)


class Directory:
    """Cursor over a directory's entry slots, growing the chain on demand."""

    def __init__(self, vol: Volume, blocks: list[int], fixed: bool):
        self.vol = vol
        self.blocks = blocks            # block numbers, key block first
        self.fixed = fixed              # the root volume directory cannot grow
        self.cursor = (0, 1)            # entry 0 of the key block is the header
        self.count = 0

    def key_block(self) -> int:
        return self.blocks[0]

    def alloc_slot(self) -> tuple[int, int, int]:
        """Reserve the next entry slot. Returns (byte offset, block#, 0-based
        entry index within that block) and bumps the directory's file count."""
        bi, ei = self.cursor
        if ei >= ENTRIES_PER_BLOCK:
            bi, ei = bi + 1, 0
            if bi >= len(self.blocks):
                if self.fixed:
                    raise ValueError("volume directory full")
                newb = self.vol.alloc_block()
                prevb = self.blocks[-1]
                self.vol.w16(prevb * BLOCK + 2, newb)   # prev.next -> new
                self.vol.w16(newb * BLOCK + 0, prevb)    # new.prev -> prev
                self.vol.w16(newb * BLOCK + 2, 0)        # new.next -> end
                self.blocks.append(newb)
        block = self.blocks[bi]
        off = block * BLOCK + ENTRY_BASE + ei * ENTRY_LEN
        self.cursor = (bi, ei + 1)
        self.count += 1
        self.vol.w16(self.key_block() * BLOCK + ENTRY_BASE + 0x21, self.count)
        return off, block, ei


def write_file_data(vol: Volume, data: bytes) -> tuple[int, int, int]:
    """Lay a file's data into freshly allocated blocks. Returns
    (storage_type, key_block, blocks_used)."""
    if len(data) > SAPLING_MAX:
        raise NotImplementedError(
            f"tree files (>{SAPLING_MAX} bytes) are not supported by this mkfs"
        )
    if len(data) <= SEEDLING_MAX:
        key = vol.alloc_block()
        vol.w(key * BLOCK, data)
        return ST_SEEDLING, key, 1

    # Sapling: key block is an index of 256 data-block pointers, stored as 256
    # low bytes ($00..$FF) followed by 256 high bytes ($100..$1FF).
    nblocks = (len(data) + BLOCK - 1) // BLOCK
    index = vol.alloc_block()
    for i in range(nblocks):
        db = vol.alloc_block()
        chunk = data[i * BLOCK:(i + 1) * BLOCK]
        vol.w(db * BLOCK, chunk)
        vol.img[index * BLOCK + i] = db & 0xFF
        vol.img[index * BLOCK + 0x100 + i] = db >> 8
    return ST_SAPLING, index, 1 + nblocks


def write_file_entry(vol: Volume, off: int, storage: int, name: str, ftype: int,
                     key: int, blocks_used: int, eof: int, header_ptr: int) -> None:
    """Write a 39-byte file/subdirectory entry at byte offset `off`."""
    vol.img[off + 0x00] = (storage << 4) | len(name)
    vol.w(off + 0x01, name.encode("ascii").ljust(MAX_NAME, b"\x00"))
    vol.img[off + 0x10] = ftype
    vol.w16(off + 0x11, key)
    vol.w16(off + 0x13, blocks_used)
    vol.w(off + 0x15, eof.to_bytes(3, "little"))
    # 0x18 creation date/time, 0x1C/0x1D version: left zero
    vol.img[off + 0x1E] = ACCESS
    # 0x1F aux_type, 0x21 modification date/time: left zero
    vol.w16(off + 0x25, header_ptr)


def write_subdir_header(vol: Volume, key: int, name: str,
                        parent_pointer: int, parent_entry: int) -> None:
    """Write the subdirectory header into entry 0 of a subdir's key block."""
    off = key * BLOCK + ENTRY_BASE
    vol.img[off + 0x00] = (ST_SUBDIR_HEADER << 4) | len(name)
    vol.w(off + 0x01, name.encode("ascii").ljust(MAX_NAME, b"\x00"))
    vol.img[off + 0x10] = SUBDIR_MARKER
    vol.img[off + 0x1E] = ACCESS
    vol.img[off + 0x1F] = ENTRY_LEN
    vol.img[off + 0x20] = ENTRIES_PER_BLOCK
    # 0x21 file_count: maintained by Directory
    vol.w16(off + 0x23, parent_pointer)
    vol.img[off + 0x25] = parent_entry          # 1-based entry# in parent block
    vol.img[off + 0x26] = ENTRY_LEN


def add_file(vol: Volume, directory: Directory, name: str, data: bytes) -> None:
    storage, key, blocks_used = write_file_data(vol, data)
    off, _, _ = directory.alloc_slot()
    write_file_entry(vol, off, storage, name, file_type_for(name),
                     key, blocks_used, len(data), directory.key_block())


def add_subdir(vol: Volume, parent: Directory, name: str) -> Directory:
    """Create a subdirectory under `parent` and return its Directory. The
    parent entry is reserved now (so the header can record its parent
    back-link) and finalised after the caller has populated the subdir."""
    key = vol.alloc_block()
    off, pblock, eidx = parent.alloc_slot()
    write_subdir_header(vol, key, name, pblock, eidx + 1)
    sub = Directory(vol, [key], fixed=False)
    sub._parent_entry_off = off                 # finalised in finalize_subdir
    sub._parent_header = parent.key_block()
    sub._name = name
    return sub


def finalize_subdir(vol: Volume, sub: Directory) -> None:
    """Write the parent's directory entry now that the subdir's block count is
    known (a subdir grows as entries are added)."""
    blocks_used = len(sub.blocks)
    write_file_entry(vol, sub._parent_entry_off, ST_SUBDIR, sub._name, FT_DIR,
                     sub.key_block(), blocks_used, blocks_used * BLOCK,
                     sub._parent_header)


def build_tree(vol: Volume, directory: Directory, src: Path,
               prefix: tuple, expected: dict, seen: set) -> None:
    for child in sorted(src.iterdir(), key=lambda p: p.name):
        if child.is_symlink():
            continue                    # ProDOS has no symlinks (as hu-basic/hfs)
        name = prodos_name(child.name)
        key = prefix + (name,)
        if key in seen:
            raise ValueError(f"ProDOS name collision: {'/'.join(key)}")
        seen.add(key)
        if child.is_dir():
            sub = add_subdir(vol, directory, name)
            build_tree(vol, sub, child, key, expected, seen)
            finalize_subdir(vol, sub)
        elif child.is_file():
            data = child.read_bytes()
            add_file(vol, directory, name, data)
            expected[key] = data


# ---- read-back / self-check ----

def _iter_entries(vol: Volume, key_block: int):
    blk, first = key_block, True
    while blk != 0:
        base = blk * BLOCK
        for ei in range(1 if first else 0, ENTRIES_PER_BLOCK):
            yield base + ENTRY_BASE + ei * ENTRY_LEN
        blk = int.from_bytes(vol.img[base + 2:base + 4], "little")
        first = False


def _read_file(vol: Volume, storage: int, key: int, eof: int) -> bytes:
    if storage == ST_SEEDLING:
        return bytes(vol.img[key * BLOCK:key * BLOCK + eof])
    nblocks = (eof + BLOCK - 1) // BLOCK
    idx = key * BLOCK
    data = bytearray()
    for i in range(nblocks):
        db = vol.img[idx + i] | (vol.img[idx + 0x100 + i] << 8)
        data += vol.img[db * BLOCK:(db + 1) * BLOCK]
    return bytes(data[:eof])


def extract_dir(vol: Volume, key_block: int, prefix: tuple, out: dict) -> None:
    for off in _iter_entries(vol, key_block):
        b0 = vol.img[off]
        storage, namelen = b0 >> 4, b0 & 0x0F
        if storage == 0 or namelen == 0:
            continue
        name = vol.img[off + 0x01:off + 0x01 + namelen].decode("ascii")
        key = int.from_bytes(vol.img[off + 0x11:off + 0x13], "little")
        if storage == ST_SUBDIR:
            extract_dir(vol, key, prefix + (name,), out)
        elif storage in (ST_SEEDLING, ST_SAPLING):
            eof = int.from_bytes(vol.img[off + 0x15:off + 0x18], "little")
            out[prefix + (name,)] = _read_file(vol, storage, key, eof)


def verify_roundtrip(vol: Volume, expected: dict) -> None:
    got: dict = {}
    extract_dir(vol, VOLDIR_START, (), got)
    if got != expected:
        miss = set(expected) - set(got)
        extra = set(got) - set(expected)
        if miss:
            raise AssertionError(f"round-trip: missing {sorted('/'.join(k) for k in miss)}")
        if extra:
            raise AssertionError(f"round-trip: unexpected {sorted('/'.join(k) for k in extra)}")
        for k in expected:
            if got[k] != expected[k]:
                raise AssertionError(f"round-trip mismatch for {'/'.join(k)}")


def create_image(output: Path, src_dir: Path, volume_name: str = "BASIC") -> None:
    vol = Volume(volume_name)
    root = Directory(vol, list(range(VOLDIR_START, VOLDIR_START + VOLDIR_BLOCKS)),
                     fixed=True)
    expected: dict = {}
    build_tree(vol, root, src_dir, (), expected, set())
    verify_roundtrip(vol, expected)
    output.write_bytes(vol.img)


def main() -> int:
    if len(sys.argv) != 3:
        sys.stderr.write("usage: mkprodos.py OUTPUT.po SRC_DIR\n")
        return 2
    output, src = Path(sys.argv[1]), Path(sys.argv[2])
    if not src.is_dir():
        sys.stderr.write(f"mkprodos.py: {src} is not a directory\n")
        return 2
    create_image(output, src)
    nfiles = sum(1 for p in src.rglob("*") if p.is_file() and not p.is_symlink())
    sys.stdout.write(
        f"wrote {output} ({output.stat().st_size} bytes, {nfiles} files)\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
