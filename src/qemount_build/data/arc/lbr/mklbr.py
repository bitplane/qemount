"""Create a CP/M LBR (Library) archive from files in a tar archive."""

import struct
import sys
import tarfile

RECORD_SIZE = 128
DIR_ENTRY_SIZE = 32


def cpm_name(filename):
    """Convert a filename to CP/M 8.3 format (space-padded)."""
    name = filename.upper().replace("/", "").replace(".", " ", 1)
    if " " in name:
        base, ext = name.split(" ", 1)
    else:
        base, ext = name, ""
    return base[:8].ljust(8) + ext[:3].ljust(3)


def pad_to_record(data):
    """Pad data to a multiple of 128 bytes."""
    remainder = len(data) % RECORD_SIZE
    if remainder:
        data += b"\x1a" * (RECORD_SIZE - remainder)
    return data


def write_lbr(output_path, tar_path):
    files = []
    with tarfile.open(tar_path) as tf:
        for member in tf.getmembers():
            if member.isfile():
                f = tf.extractfile(member)
                if f:
                    name = member.name.split("/")[-1]
                    files.append((name, f.read()))

    # Directory needs: 1 entry for itself + 1 per file, 4 entries per record
    n_entries = 1 + len(files)
    dir_records = (n_entries * DIR_ENTRY_SIZE + RECORD_SIZE - 1) // RECORD_SIZE

    # Build directory
    directory = bytearray()

    # Entry 0: the directory itself
    entry = bytearray(DIR_ENTRY_SIZE)
    entry[0] = 0x00  # active
    entry[1:12] = b"           "  # 11 spaces
    struct.pack_into("<HH", entry, 12, 0, dir_records)  # start=0, count=dir_records
    directory.extend(entry)

    # Calculate file positions
    data_start = dir_records  # first data record index
    current_record = data_start
    file_entries = []

    for name, data in files:
        padded = pad_to_record(data)
        n_records = len(padded) // RECORD_SIZE
        pad_count = len(padded) - len(data)
        file_entries.append((name, current_record, n_records, pad_count, padded))
        current_record += n_records

    # File directory entries
    for name, start, count, pad_count, _ in file_entries:
        entry = bytearray(DIR_ENTRY_SIZE)
        entry[0] = 0x00  # active
        entry[1:12] = cpm_name(name).encode("ascii")
        struct.pack_into("<HH", entry, 12, start, count)
        entry[26] = pad_count
        directory.extend(entry)

    # Fill remaining directory space with unused entries
    total_dir_bytes = dir_records * RECORD_SIZE
    while len(directory) < total_dir_bytes:
        entry = bytearray(DIR_ENTRY_SIZE)
        entry[0] = 0xFF  # unused
        directory.extend(entry)

    directory = directory[:total_dir_bytes]

    # Write output
    with open(output_path, "wb") as out:
        out.write(directory)
        for _, _, _, _, padded in file_entries:
            out.write(padded)


if __name__ == "__main__":
    write_lbr(sys.argv[1], sys.argv[2])
