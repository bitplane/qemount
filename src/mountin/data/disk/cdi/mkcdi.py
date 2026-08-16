#!/usr/bin/env python3
"""
Simple CDI (DiscJuggler) image creator.

Creates CDI v3.5 images from raw track data.

Usage:
    mkcdi.py output.cdi track1.pcm:audio track2.iso:mode1 ...

Track types:
    audio  - CDDA audio (2352 bytes/sector, mode 0)
    mode1  - Mode 1 data (2048 bytes/sector, mode 1)
    mode2  - Mode 2 data (2336 bytes/sector, mode 2)
"""

import struct
import sys
from pathlib import Path


# CDI version constants
CDI_V35 = 0x80000006

# Track marker (appears twice before each track header)
TRACK_MARKER = bytes([0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF])

# Track modes
MODES = {
    "audio": 0,
    "mode1": 1,
    "mode2": 2,
}

# Sector size codes (0=2048, 1=2336, 2=2352)
SECTOR_SIZE_CODES = {
    2048: 0,
    2336: 1,
    2352: 2,
}

SECTOR_SIZES = {
    "audio": 2352,
    "mode1": 2048,
    "mode2": 2336,
}


def write_le16(f, val):
    f.write(struct.pack("<H", val))


def write_le32(f, val):
    f.write(struct.pack("<I", val))


def write_track_header(f, track_num: int, mode: int, sector_size: int,
                       pregap: int, length: int, start_lba: int):
    """Write a track header block."""
    # Extra data marker (0 = no extra data)
    write_le32(f, 0)

    # Two track markers
    f.write(TRACK_MARKER)
    f.write(TRACK_MARKER)

    # 4 bytes padding
    f.write(b'\x00' * 4)

    # Filename length + filename (empty)
    f.write(b'\x00')  # 0 length filename

    # 11 + 4 + 4 bytes padding
    f.write(b'\x00' * 19)

    # DJ4 marker check (not DJ4, so just 0)
    write_le32(f, 0)

    # 2 bytes padding
    f.write(b'\x00' * 2)

    # Pregap length
    write_le32(f, pregap)

    # Track length (in sectors)
    write_le32(f, length)

    # 6 bytes padding
    f.write(b'\x00' * 6)

    # Mode
    write_le32(f, mode)

    # 12 bytes padding
    f.write(b'\x00' * 12)

    # Start LBA
    write_le32(f, start_lba)

    # Total length
    write_le32(f, pregap + length)

    # 16 bytes padding
    f.write(b'\x00' * 16)

    # Sector size code
    write_le32(f, SECTOR_SIZE_CODES[sector_size])

    # 29 bytes padding
    f.write(b'\x00' * 29)

    # v3.5 extra: 5 bytes + temp marker
    f.write(b'\x00' * 5)
    write_le32(f, 0)  # Not 0xffffffff, so no extra 78 bytes


def create_cdi(output_path: Path, tracks: list[tuple[Path, str]]):
    """
    Create a CDI image from track files.

    tracks: list of (path, type) tuples where type is audio/mode1/mode2
    """
    with open(output_path, "wb") as f:
        track_info = []
        current_lba = 0

        # Write track data and collect info
        for track_path, track_type in tracks:
            data = track_path.read_bytes()
            sector_size = SECTOR_SIZES[track_type]

            # Pad to sector boundary if needed
            remainder = len(data) % sector_size
            if remainder:
                data += b'\x00' * (sector_size - remainder)

            f.write(data)

            num_sectors = len(data) // sector_size
            track_info.append({
                "mode": MODES[track_type],
                "sector_size": sector_size,
                "pregap": 0,
                "length": num_sectors,
                "start_lba": current_lba,
            })
            current_lba += num_sectors

        # Record header position
        header_pos = f.tell()

        # Write session header (1 session)
        write_le16(f, 1)  # Number of sessions

        # Write track count for this session
        write_le16(f, len(tracks))

        # Write track headers
        for i, info in enumerate(track_info):
            write_track_header(
                f,
                track_num=i + 1,
                mode=info["mode"],
                sector_size=info["sector_size"],
                pregap=info["pregap"],
                length=info["length"],
                start_lba=info["start_lba"],
            )

        # Session footer: 4 + 8 bytes + 1 byte (v3.5)
        f.write(b'\x00' * 4)
        f.write(b'\x00' * 8)
        f.write(b'\x00')  # v3.5 extra byte

        # Calculate header offset for footer
        file_size = f.tell() + 8  # +8 for footer we're about to write
        header_offset = file_size - header_pos

        # Write footer: version (LE32) + header_offset (LE32)
        write_le32(f, CDI_V35)
        write_le32(f, header_offset)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    output = Path(sys.argv[1])
    tracks = []

    for arg in sys.argv[2:]:
        if ':' not in arg:
            print(f"Error: track must be path:type, got {arg}")
            sys.exit(1)
        path, track_type = arg.rsplit(':', 1)
        if track_type not in MODES:
            print(f"Error: unknown track type {track_type}")
            print(f"Valid types: {', '.join(MODES.keys())}")
            sys.exit(1)
        tracks.append((Path(path), track_type))

    create_cdi(output, tracks)
    print(f"Created: {output}")


if __name__ == "__main__":
    main()
