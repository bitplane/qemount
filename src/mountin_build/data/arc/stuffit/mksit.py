"""
StuffIt 1.5.1 (.sit) archive writer.

Creates valid StuffIt archives with the classic SIT!/rLau header format.
Currently supports method 0 (store) only. The structure is designed so
that additional compression methods (RLE, LZW, Huffman, etc.) can be
added as simple functions that take bytes and return bytes.

Format reference:
    Raymond Lau, StuffIt 1.5.1 (1987)
    MacPaw/XADMaster XADStuffItParser
    thecloudexpanse/sit
"""

import struct
import os
import sys
from pathlib import Path

# Mac epoch is 2082844800 seconds before Unix epoch (1904-01-01 vs 1970-01-01)
MAC_EPOCH_OFFSET = 2082844800

# CRC-16/ARC table (polynomial 0xA001, reflected)
_CRC_TABLE = []
for _i in range(256):
    _crc = _i
    for _ in range(8):
        _crc = (_crc >> 1) ^ 0xA001 if _crc & 1 else _crc >> 1
    _CRC_TABLE.append(_crc)


def crc16(data: bytes, crc: int = 0) -> int:
    """CRC-16/ARC as used by StuffIt."""
    for b in data:
        crc = (_CRC_TABLE[(crc ^ b) & 0xFF] ^ (crc >> 8)) & 0xFFFF
    return crc


# -- Compression methods -----------------------------------------------------
# Each method is a callable: (data: bytes) -> bytes
# Method 0 is identity (store). Others can be added here later.

def compress_store(data: bytes) -> bytes:
    return data


METHODS = {
    0: compress_store,
}


# -- Archive header -----------------------------------------------------------

ARCHIVE_HEADER = struct.Struct(">4s H I 4s B 7s")  # 22 bytes
ARCHIVE_SIG1 = b"SIT!"
ARCHIVE_SIG2 = b"rLau"
ARCHIVE_VERSION = 1


def pack_archive_header(num_files: int, arc_length: int) -> bytes:
    return ARCHIVE_HEADER.pack(
        ARCHIVE_SIG1, num_files, arc_length,
        ARCHIVE_SIG2, ARCHIVE_VERSION, b"\x00" * 7,
    )


# -- File entry header --------------------------------------------------------

FILE_ENTRY_SIZE = 112


def pack_file_entry(
    name: str,
    data: bytes,
    resource: bytes = b"",
    file_type: bytes = b"TEXT",
    creator: bytes = b"ttxt",
    method: int = 0,
) -> bytes:
    """Pack a single file entry header + fork data.

    Returns the complete entry: 112-byte header + resource fork + data fork.
    """
    compress = METHODS[method]
    comp_resource = compress(resource)
    comp_data = compress(data)

    now_mac = int(os.times()[4]) + MAC_EPOCH_OFFSET  # rough, overridden below
    try:
        import time
        now_mac = int(time.time()) + MAC_EPOCH_OFFSET
    except Exception:
        pass

    # Build the 112-byte header
    hdr = bytearray(FILE_ENTRY_SIZE)

    # Compression methods for resource and data forks
    hdr[0] = method  # compRMethod
    hdr[1] = method  # compDMethod

    # Filename as Pascal string (STR63) at offset 2
    name_bytes = name.encode("mac_roman", errors="replace")[:63]
    hdr[2] = len(name_bytes)
    hdr[3:3 + len(name_bytes)] = name_bytes

    # Mac file type and creator at offset 66
    struct.pack_into(">4s4s", hdr, 66, file_type[:4].ljust(4), creator[:4].ljust(4))

    # Finder flags at offset 74
    struct.pack_into(">H", hdr, 74, 0)

    # Dates at offsets 76 and 80
    struct.pack_into(">II", hdr, 76, now_mac, now_mac)

    # Fork lengths
    struct.pack_into(">I", hdr, 84, len(resource))       # rsrcLength
    struct.pack_into(">I", hdr, 88, len(data))            # dataLength
    struct.pack_into(">I", hdr, 92, len(comp_resource))   # compRLength
    struct.pack_into(">I", hdr, 96, len(comp_data))       # compDLength

    # CRCs of decompressed fork data
    struct.pack_into(">H", hdr, 100, crc16(resource))     # rsrcCRC
    struct.pack_into(">H", hdr, 102, crc16(data))         # dataCRC

    # Header CRC covers bytes 0-109
    struct.pack_into(">H", hdr, 110, crc16(bytes(hdr[:110])))

    return bytes(hdr) + comp_resource + comp_data


# -- Archive assembly ---------------------------------------------------------

def create_archive(files: list[tuple[str, bytes]], method: int = 0) -> bytes:
    """Create a StuffIt archive from a list of (name, data) pairs.

    All files are stored with empty resource forks (data fork only),
    which is normal for non-Mac-specific content.
    """
    entries = b"".join(
        pack_file_entry(name, data, method=method)
        for name, data in files
    )
    arc_length = ARCHIVE_HEADER.size + len(entries)
    return pack_archive_header(len(files), arc_length) + entries


def create_archive_from_dir(directory: Path, method: int = 0) -> bytes:
    """Create a StuffIt archive from all regular files in a directory."""
    files = []
    for path in sorted(directory.iterdir()):
        if path.is_file():
            files.append((path.name, path.read_bytes()))
    return create_archive(files, method=method)


# -- CLI ----------------------------------------------------------------------

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} output.sit directory/", file=sys.stderr)
        sys.exit(1)

    output = Path(sys.argv[1])
    directory = Path(sys.argv[2])

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(create_archive_from_dir(directory))


if __name__ == "__main__":
    main()
