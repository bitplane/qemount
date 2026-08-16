"""Create a minimal OLE2 Compound Document from files."""

import struct
import sys


def write_ole(output_path, files):
    """Write a minimal OLE2 file containing the given files as streams.

    This creates the simplest valid OLE2 structure:
    - Header (512 bytes)
    - FAT sector
    - Directory sectors
    - Data sectors
    """
    SECTOR_SIZE = 512
    DIR_ENTRY_SIZE = 128

    # Collect stream data
    streams = []
    for path, data in files:
        name = path.split("/")[-1][:31]  # OLE names max 32 chars
        streams.append((name, data))

    # Calculate layout
    # Sector 0: FAT
    # Sector 1+: Directory (1 sector = 4 entries)
    # Remaining: Data sectors
    n_dir_entries = 1 + len(streams)  # root + streams
    n_dir_sectors = (n_dir_entries * DIR_ENTRY_SIZE + SECTOR_SIZE - 1) // SECTOR_SIZE

    # Assign data sectors
    data_start = 1 + n_dir_sectors  # after FAT + directory
    sector_map = []
    for name, data in streams:
        n_sectors = (len(data) + SECTOR_SIZE - 1) // SECTOR_SIZE if data else 0
        sector_map.append((data_start, n_sectors))
        data_start += n_sectors

    total_sectors = data_start
    out = bytearray()

    # === Header (512 bytes) ===
    header = bytearray(SECTOR_SIZE)
    # Magic
    header[0:8] = b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1"
    # Minor version, major version
    struct.pack_into("<HH", header, 0x18, 0x003E, 0x0003)
    # Byte order (little-endian)
    struct.pack_into("<H", header, 0x1C, 0xFFFE)
    # Sector size power (9 = 512)
    struct.pack_into("<H", header, 0x1E, 9)
    # Mini sector size power (6 = 64)
    struct.pack_into("<H", header, 0x20, 6)
    # Total FAT sectors
    struct.pack_into("<I", header, 0x2C, 1)
    # First directory sector
    struct.pack_into("<I", header, 0x30, 1)
    # Mini stream cutoff (4096)
    struct.pack_into("<I", header, 0x38, 0x1000)
    # First mini FAT sector (none)
    struct.pack_into("<I", header, 0x3C, 0xFFFFFFFE)
    # Mini FAT sector count
    struct.pack_into("<I", header, 0x40, 0)
    # First DIFAT sector (none)
    struct.pack_into("<I", header, 0x44, 0xFFFFFFFE)
    # DIFAT sector count
    struct.pack_into("<I", header, 0x48, 0)
    # DIFAT array (first entry = sector 0 for FAT)
    struct.pack_into("<I", header, 0x4C, 0)
    # Rest of DIFAT = free
    for i in range(1, 109):
        struct.pack_into("<I", header, 0x4C + i * 4, 0xFFFFFFFF)
    out.extend(header)

    # === Sector 0: FAT ===
    fat = bytearray(SECTOR_SIZE)
    # Sector 0 = FAT sector marker
    struct.pack_into("<I", fat, 0, 0xFFFFFFFD)
    # Directory sectors chain
    for i in range(n_dir_sectors):
        sid = 1 + i
        next_sid = sid + 1 if i < n_dir_sectors - 1 else 0xFFFFFFFE
        struct.pack_into("<I", fat, sid * 4, next_sid)
    # Data sector chains
    for start, count in sector_map:
        for j in range(count):
            sid = start + j
            next_sid = sid + 1 if j < count - 1 else 0xFFFFFFFE
            struct.pack_into("<I", fat, sid * 4, next_sid)
    # Fill rest as free
    for i in range(total_sectors, SECTOR_SIZE // 4):
        struct.pack_into("<I", fat, i * 4, 0xFFFFFFFF)
    out.extend(fat)

    # === Directory sectors ===
    dir_data = bytearray(n_dir_sectors * SECTOR_SIZE)

    def write_dir_entry(idx, name, entry_type, start_sector, size, child=-1):
        off = idx * DIR_ENTRY_SIZE
        encoded = name.encode("utf-16-le") + b"\x00\x00"
        dir_data[off : off + len(encoded)] = encoded
        struct.pack_into("<H", dir_data, off + 0x40, len(encoded))
        dir_data[off + 0x42] = entry_type  # 5=root, 2=stream
        dir_data[off + 0x43] = 1  # black node
        # Left/right/child SIDs
        struct.pack_into("<I", dir_data, off + 0x44, 0xFFFFFFFF)  # left
        struct.pack_into("<I", dir_data, off + 0x48, 0xFFFFFFFF)  # right
        struct.pack_into("<I", dir_data, off + 0x4C, child if child >= 0 else 0xFFFFFFFF)
        struct.pack_into("<I", dir_data, off + 0x74, start_sector)
        struct.pack_into("<I", dir_data, off + 0x78, size)

    # Root entry - child points to first stream
    child_sid = 1 if streams else -1
    write_dir_entry(0, "Root Entry", 5, 0xFFFFFFFE, 0, child=child_sid)

    # Stream entries as a simple binary tree (left-heavy)
    for i, (name, data) in enumerate(streams):
        start, count = sector_map[i]
        left = i + 2 if i + 2 <= len(streams) else -1
        write_dir_entry(i + 1, name, 2, start, len(data))
        if left > 0 and left <= len(streams):
            struct.pack_into("<I", dir_data, (i + 1) * DIR_ENTRY_SIZE + 0x44, left)

    out.extend(dir_data)

    # === Data sectors ===
    for i, (name, data) in enumerate(streams):
        start, count = sector_map[i]
        padded = data + b"\x00" * (count * SECTOR_SIZE - len(data))
        out.extend(padded)

    with open(output_path, "wb") as f:
        f.write(out)


if __name__ == "__main__":
    import os
    import tarfile

    output = sys.argv[1]
    tar_path = sys.argv[2]

    files = []
    with tarfile.open(tar_path) as tf:
        for member in tf.getmembers():
            if member.isfile():
                f = tf.extractfile(member)
                if f:
                    files.append((member.name, f.read()))

    write_ole(output, files)
