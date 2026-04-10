---
title: EWF (Expert Witness Format)
created: 1998
related:
  - format/disk/raw
  - format/disk/aaru
detect:
  any:
    - offset: 0
      type: string
      value: "EVF\x09\x0d\x0a\xff\x00"
      name: "EWF v1 (E01)"
    - offset: 0
      type: string
      value: "EVF2\x0d\x0a\x81\x00"
      name: "EWF v2 (Ex01)"
---

# Expert Witness Format (EWF / E01)

EWF is the dominant forensic disk image format, used by law enforcement and
forensic analysts worldwide. Originally created by ASR Data for their SMART
forensic tool, it was adopted and extended by Guidance Software for EnCase
(first released February 1998). Guidance Software was acquired by OpenText
in 2017. EnCase 7 (2012) introduced EWF v2 (Ex01).

## Characteristics

- Bit-for-bit disk image container with forensic metadata
- Zlib compression (v1), zlib or bzip2 (v2)
- Multi-segment files (.E01, .E02, ... .E99, .EAA, ... .ZZZ)
- Per-chunk Adler-32 checksums
- Whole-image MD5 and SHA1 hashes
- Case metadata (examiner, case number, evidence number, notes, dates)
- Maximum ~14295 segments per image (v1), more with v2

## Structure

- Magic: `EVF\x09\x0d\x0a\xff\x00` (v1) or `EVF2\x0d\x0a\x81\x00` (v2)
- Segment files contain sections: header, volume, sectors, table, hash, done
- Default chunk size: 32768 bytes (64 sectors x 512 bytes)
- Compressed chunks stored only when smaller than uncompressed

## File Header (v1) - 13 bytes

| Offset | Size | Field              |
|--------|------|--------------------|
| 0x00   | 8    | Signature          |
| 0x08   | 1    | Start of fields    |
| 0x09   | 2    | Segment number     |
| 0x0B   | 2    | End of fields      |

## File Header (v2) - 32 bytes

| Offset | Size | Field                     |
|--------|------|---------------------------|
| 0x00   | 8    | Signature                 |
| 0x08   | 1    | Major version             |
| 0x09   | 1    | Minor version             |
| 0x0A   | 2    | Compression method        |
| 0x0C   | 4    | Segment file number       |
| 0x10   | 16   | Set identifier (GUID v4)  |

## Sections (v1)

Each section preceded by a 76-byte descriptor:

| Offset | Size | Field                        |
|--------|------|------------------------------|
| 0x00   | 16   | Type string                  |
| 0x10   | 8    | Next section offset          |
| 0x18   | 8    | Section size                 |
| 0x20   | 40   | Padding                      |
| 0x48   | 4    | Adler-32 checksum            |

Section types: header, header2, volume, data, sectors, table, table2,
digest, hash, error2, session, done.

## Multi-segment Naming

v1: `.E01`-`.E99`, `.EAA`-`.EZZ`, `.FAA`-`.ZZZ`
v2: `.Ex01`-`.Ex99`, `.ExAA`-`.ExZZ`, `.EyAA`-`.EzZZ`

First segment contains headers and volume metadata. Last segment contains
digest, hash, and done sections. Intermediate segments contain sectors and
table data.

## Compression

v1 uses zlib only, with three levels: none (0x00), fast (0x01), best (0x02).
Header sections are always zlib-compressed regardless of chunk compression
setting. v2 adds bzip2 (0x02) and requires 16-byte alignment of all chunks.

## Integrity

- Per-chunk: Adler-32 (not CRC32) for uncompressed chunks; zlib-intrinsic
  Adler-32 for compressed chunks
- Per-section: Adler-32 on section descriptors; v2 adds MD5 of section data
- Whole-image: MD5 hash (all versions), SHA1 hash (EnCase 6+/v2)

## Detection

8-byte signature at offset 0. `EVF\x09\x0d\x0a\xff\x00` for v1 (E01),
`EVF2\x0d\x0a\x81\x00` for v2 (Ex01). Also watch for logical evidence
variants: `LVF\x09\x0d\x0a\xff\x00` (L01) and `LEF2\x0d\x0a\x81\x00`
(Lx01).

## Tools

```sh
# Mount EWF image as raw block device (FUSE)
ewfmount image.E01 /mnt/ewf

# Show image metadata
ewfinfo image.E01

# Verify image integrity
ewfverify image.E01

# Export to raw
ewfexport -t raw image.E01
```

All tools provided by libewf (https://github.com/libyal/libewf), maintained
by Joachim Metz as part of the libyal project.
