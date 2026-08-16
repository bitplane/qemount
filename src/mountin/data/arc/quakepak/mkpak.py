"""Create a Quake PAK file from template files."""

import struct
import sys
import tarfile


def write_pak(output_path, tar_path):
    files = []
    with tarfile.open(tar_path) as tf:
        for member in tf.getmembers():
            if member.isfile():
                f = tf.extractfile(member)
                if f:
                    # PAK filenames are 56 bytes max
                    name = member.name[:55]
                    files.append((name, f.read()))

    # PAK structure: header + data + directory
    # Header: "PACK" (4) + diroffset (4) + dirsize (4)
    header_size = 12
    total_data = sum(len(d) for _, d in files)
    dir_offset = header_size + total_data
    dir_size = len(files) * 64  # 56 name + 4 offset + 4 size

    with open(output_path, "wb") as out:
        out.write(b"PACK")
        out.write(struct.pack("<I", dir_offset))
        out.write(struct.pack("<I", dir_size))

        # Write file data
        for name, data in files:
            out.write(data)

        # Write directory
        offset = header_size
        for name, data in files:
            out.write(name.encode("ascii").ljust(56, b"\x00"))
            out.write(struct.pack("<I", offset))
            out.write(struct.pack("<I", len(data)))
            offset += len(data)


if __name__ == "__main__":
    write_pak(sys.argv[1], sys.argv[2])
