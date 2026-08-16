#!/usr/bin/env python3
"""
Simple NRG (Nero Burning ROM) image creator.

Creates NRG images from raw track data. Uses NER5 format with ETN2 chunks
(TAO mode) for simplicity.

Usage:
    mknrg.py output.nrg track1.pcm:audio track2.iso:mode1 ...

Track types:
    audio  - CDDA audio (2352 bytes/sector)
    mode1  - Mode 1 data (2048 bytes/sector)
    mode2  - Mode 2 data (2336 bytes/sector)
"""

import struct
import sys
from pathlib import Path


# NRG mode codes (from libmirage)
MODE_CODES = {
    "audio": 0x07,   # Audio (2352)
    "mode1": 0x00,   # Mode 1 (2048)
    "mode2": 0x02,   # Mode 2 (2336)
}

SECTOR_SIZES = {
    "audio": 2352,
    "mode1": 2048,
    "mode2": 2336,
}


def write_chunk(f, chunk_id: bytes, data: bytes):
    """Write a chunk: 4-byte ID + 4-byte BE length + data."""
    f.write(chunk_id)
    f.write(struct.pack(">I", len(data)))
    f.write(data)


def write_etn2_entry(offset: int, size: int, mode: int, sector: int) -> bytes:
    """Create an ETN2 track entry (24 bytes)."""
    # ETN2: 8-byte offset, 8-byte size, 4-byte mode, 4-byte start sector
    return struct.pack(">QQII", offset, size, mode, sector)


def create_nrg(output_path: Path, tracks: list[tuple[Path, str]]):
    """
    Create an NRG image from track files.

    tracks: list of (path, type) tuples where type is audio/mode1/mode2
    """
    with open(output_path, "wb") as f:
        track_entries = []
        current_offset = 0
        current_sector = 0

        # Write track data
        for track_path, track_type in tracks:
            data = track_path.read_bytes()
            sector_size = SECTOR_SIZES[track_type]

            # Pad to sector boundary if needed
            remainder = len(data) % sector_size
            if remainder:
                data += b'\x00' * (sector_size - remainder)

            f.write(data)

            # Record track info for ETN2 chunk
            mode_code = MODE_CODES[track_type]
            track_entries.append(write_etn2_entry(
                current_offset, len(data), mode_code, current_sector
            ))

            current_offset += len(data)
            current_sector += len(data) // sector_size

        # Record where chunks start
        chunk_offset = f.tell()

        # Write ETN2 chunk (track extent info)
        etn2_data = b''.join(track_entries)
        write_chunk(f, b'ETN2', etn2_data)

        # Write END! chunk
        write_chunk(f, b'END!', b'')

        # Write NER5 footer (signature + 8-byte offset)
        f.write(b'NER5')
        f.write(struct.pack(">Q", chunk_offset))


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
        if track_type not in MODE_CODES:
            print(f"Error: unknown track type {track_type}")
            print(f"Valid types: {', '.join(MODE_CODES.keys())}")
            sys.exit(1)
        tracks.append((Path(path), track_type))

    create_nrg(output, tracks)
    print(f"Created: {output}")


if __name__ == "__main__":
    main()
