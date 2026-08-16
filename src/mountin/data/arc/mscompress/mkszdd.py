"""Create an SZDD (Microsoft Compress) file using LZSS compression."""

import struct
import sys

MAGIC = b"SZDD\x88\xf0\x27\x33"
RING_SIZE = 4096
MAX_MATCH = 18
MIN_MATCH = 3
SPACE = 0x20


def compress_szdd(data):
    """LZSS compress data in SZDD format."""
    # Ring buffer initialized to spaces
    ring = bytearray([SPACE] * RING_SIZE)
    ring_pos = RING_SIZE - MAX_MATCH

    out = bytearray()
    src = 0

    while src < len(data):
        # Collect up to 8 items per flag byte
        flag = 0
        items = bytearray()
        bit = 0

        while bit < 8 and src < len(data):
            # Search for longest match in ring buffer
            best_len = 0
            best_off = 0

            for off in range(RING_SIZE):
                match_len = 0
                while (match_len < MAX_MATCH
                       and src + match_len < len(data)
                       and ring[(off + match_len) % RING_SIZE] == data[src + match_len]):
                    match_len += 1
                if match_len > best_len:
                    best_len = match_len
                    best_off = off

            if best_len >= MIN_MATCH:
                # Back-reference: low byte = offset_low, high byte = (offset_high << 4) | (length - 3)
                lo = best_off & 0xFF
                hi = ((best_off >> 8) & 0x0F) | ((best_len - MIN_MATCH) << 4)
                items.append(lo)
                items.append(hi)
                # Advance ring buffer
                for i in range(best_len):
                    ring[ring_pos % RING_SIZE] = data[src + i]
                    ring_pos += 1
                src += best_len
            else:
                # Literal byte
                flag |= (1 << bit)
                items.append(data[src])
                ring[ring_pos % RING_SIZE] = data[src]
                ring_pos += 1
                src += 1

            bit += 1

        out.append(flag)
        out.extend(items)

    return bytes(out)


def write_szdd(output_path, input_path):
    with open(input_path, "rb") as f:
        data = f.read()

    compressed = compress_szdd(data)

    # Last char of original filename (the one replaced by _ in DOS)
    # Use 'r' for .tar -> .ta_
    last_char = ord("r")

    with open(output_path, "wb") as f:
        f.write(MAGIC)
        f.write(struct.pack("B", ord("A")))  # compression mode
        f.write(struct.pack("B", last_char))
        f.write(struct.pack("<I", len(data)))
        f.write(compressed)


if __name__ == "__main__":
    write_szdd(sys.argv[1], sys.argv[2])
