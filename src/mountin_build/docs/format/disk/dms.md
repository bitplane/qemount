---
title: DMS (Disk Masher System)
created: 1992
related:
  - format/disk/raw
detect:
  any:
    - offset: 0
      type: string
      value: "DMS!"
---

# DMS (Disk Masher System)

Amiga compressed floppy disk image format. DMS stores a track-by-track
compressed replica of an Amiga floppy, decompressing to a standard 880K ADF
image. Widely used in the Amiga demo and warez scenes for BBS distribution.

## Background

Disk Masher System was created in 1992 for the Commodore Amiga. It became the
dominant disk image distribution format because most 880K Amiga floppies
compressed below 720K, fitting on a PC floppy via CrossDOS for modem transfer.
The format is proprietary and was never formally specified; all modern
implementations are based on reverse engineering.

## File Structure

```
+---------------------------+
| File Header (56 bytes)    |  "DMS!" magic + metadata
+---------------------------+
| Track 0 Header (20 bytes) |  "TR" magic + track metadata
+---------------------------+
| Track 0 Data (variable)   |  Compressed track data
+---------------------------+
| Track 1 Header            |
+---------------------------+
| Track 1 Data              |
+---------------------------+
| ...                       |  Repeated for all tracks
+---------------------------+
```

## File Header (56 bytes)

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 4 | Signature "DMS!" |
| 10 | 2 | General info flags |
| 12 | 4 | Creation date (Unix timestamp) |
| 16 | 2 | First track number |
| 18 | 2 | Last track number |
| 21 | 3 | Total packed size |
| 25 | 3 | Total unpacked size (usually 901120) |
| 46 | 2 | DMS creator version |
| 50 | 2 | Disk type |
| 52 | 2 | Compression mode |
| 54 | 2 | Header CRC |

## Track Header (20 bytes)

| Offset | Size | Description |
|--------|------|-------------|
| 0 | 2 | Signature "TR" |
| 2 | 2 | Track number |
| 6 | 2 | Compressed size |
| 8 | 2 | Size after first decompression pass |
| 10 | 2 | Final uncompressed size |
| 12 | 1 | Flags |
| 13 | 1 | Compression mode |
| 14 | 2 | Data checksum |
| 16 | 2 | Data CRC |
| 18 | 2 | Header CRC |

## Compression Modes

| Mode | Name | Description |
|------|------|-------------|
| 0 | NONE | Uncompressed |
| 1 | SIMPLE | Run-length encoding |
| 2 | QUICK | 256-byte ring buffer |
| 3 | MEDIUM | 16384-byte ring buffer |
| 4 | DEEP | 16384-byte ring buffer + Huffman trees |
| 5 | HEAVY1 | 4096-byte ring buffer, LZH variant |
| 6 | HEAVY2 | 8192-byte ring buffer, LZH variant |

RLE (mode 1) is also applied as a second pass after modes 2-6.

## Output

Decompresses to a raw ADF (Amiga Disk File): 80 cylinders x 2 heads x
11 sectors x 512 bytes = 901120 bytes. The ADF contains an OFS or FFS
Amiga filesystem.

## Known Issues

- HEAVY2 compression had bugs in early DMS versions that could corrupt data
- The format supports encryption and embedded banners (BBS text)
- No formal specification exists; implementations are reverse-engineered

## Detection

Check for "DMS!" signature at offset 0.

## Tools

```sh
# Decompress DMS to ADF
xdms u disk.dms

# Decompress with recovery attempt
xdms u -r disk.dms
```

## References

- [xDMS](https://zakalwe.fi/~shd/foss/xdms/) - reference decompressor (Public Domain, ANSI C)
- [xDMS source](https://github.com/timofonic-retro/xdms) - GitHub mirror
- [Ancient](https://github.com/temisu/ancient) - multi-format decompressor with DMS support
- [Archive Team wiki](http://fileformats.archiveteam.org/wiki/Disk_Masher_System)
