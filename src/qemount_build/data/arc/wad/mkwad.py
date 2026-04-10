"""Create a Doom WAD file from template files."""

import struct
import sys
import tarfile


def write_wad(output_path, tar_path):
    files = []
    with tarfile.open(tar_path) as tf:
        for member in tf.getmembers():
            if member.isfile():
                f = tf.extractfile(member)
                if f:
                    # WAD lump names are 8 chars max, uppercase
                    name = member.name.split("/")[-1][:8].upper()
                    files.append((name, f.read()))

    # WAD structure: header + data lumps + directory
    # Header: "IWAD" (4) + numlumps (4) + infotableofs (4)
    header_size = 12
    data_offset = header_size
    total_data = sum(len(d) for _, d in files)
    dir_offset = header_size + total_data

    with open(output_path, "wb") as out:
        out.write(b"IWAD")
        out.write(struct.pack("<I", len(files)))
        out.write(struct.pack("<I", dir_offset))

        # Write lump data
        for name, data in files:
            out.write(data)

        # Write directory
        offset = header_size
        for name, data in files:
            out.write(struct.pack("<I", offset))
            out.write(struct.pack("<I", len(data)))
            out.write(name.encode("ascii").ljust(8, b"\x00"))
            offset += len(data)


if __name__ == "__main__":
    write_wad(sys.argv[1], sys.argv[2])
