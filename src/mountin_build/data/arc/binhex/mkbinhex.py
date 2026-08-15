"""Create a BinHex 4.0 file from the first file in a tar archive."""

import struct
import sys
import tarfile

# BinHex 4.0 character set
BINHEX_CHARS = (
    "!\"#$%&'()*+,-012345689@ABCDEFGHIJKLMNPQRSTUVXYZ[`abcdefhijklmpqr"
)


def crc_binhex(data, crc=0):
    """BinHex CRC-CCITT."""
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = (crc << 1) ^ 0x1021
            else:
                crc <<= 1
            crc &= 0xFFFF
    return crc


def rle_encode(data):
    """BinHex run-length encoding (0x90 = repeat marker)."""
    result = bytearray()
    i = 0
    while i < len(data):
        byte = data[i]
        if byte == 0x90:
            result.append(0x90)
            result.append(0x00)
            i += 1
        else:
            count = 1
            while i + count < len(data) and data[i + count] == byte and count < 255:
                count += 1
            if count >= 3:
                result.append(byte)
                result.append(0x90)
                result.append(count)
                i += count
            else:
                for _ in range(count):
                    result.append(byte)
                i += count
    return bytes(result)


def binhex_encode(data):
    """Encode bytes to BinHex base-64-like encoding."""
    result = []
    bits = 0
    n_bits = 0
    for byte in data:
        bits = (bits << 8) | byte
        n_bits += 8
        while n_bits >= 6:
            n_bits -= 6
            result.append(BINHEX_CHARS[(bits >> n_bits) & 0x3F])
    if n_bits > 0:
        result.append(BINHEX_CHARS[(bits << (6 - n_bits)) & 0x3F])
    return "".join(result)


def write_binhex(output_path, tar_path):
    # Get first file from tar
    with tarfile.open(tar_path) as tf:
        for member in tf.getmembers():
            if member.isfile():
                f = tf.extractfile(member)
                if f:
                    name = member.name.split("/")[-1][:63]
                    data = f.read()
                    break
        else:
            raise ValueError("No files in tar")

    # Build binary content
    # Header: name_len(1) + name + null(1) + version(1) + type(4) + creator(4)
    #         + flags(2) + data_len(4) + rsrc_len(4) + header_crc(2)
    name_bytes = name.encode("ascii")
    header = bytearray()
    header.append(len(name_bytes))
    header.extend(name_bytes)
    header.append(0)  # null terminator
    header.append(0)  # version
    header.extend(b"TEXT")  # type
    header.extend(b"ttxt")  # creator
    header.extend(struct.pack(">H", 0))  # flags
    header.extend(struct.pack(">I", len(data)))  # data fork length
    header.extend(struct.pack(">I", 0))  # resource fork length

    header_crc = crc_binhex(header)
    header.extend(struct.pack(">H", header_crc))

    # Data fork + CRC
    data_crc = crc_binhex(data)
    data_section = data + struct.pack(">H", data_crc)

    # Resource fork (empty) + CRC
    rsrc_crc = crc_binhex(b"")
    rsrc_section = struct.pack(">H", rsrc_crc)

    # Combine, RLE encode, then base64-like encode
    raw = bytes(header) + data_section + rsrc_section
    rle = rle_encode(raw)
    encoded = binhex_encode(rle)

    # Write with BinHex header and line wrapping
    with open(output_path, "w") as out:
        out.write("(This file must be converted with BinHex 4.0)\n")
        out.write(":")
        for i in range(0, len(encoded), 64):
            out.write(encoded[i : i + 64])
            out.write("\n")
        out.write(":\n")


if __name__ == "__main__":
    write_binhex(sys.argv[1], sys.argv[2])
