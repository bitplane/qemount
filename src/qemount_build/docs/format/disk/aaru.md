---
title: AaruFormat
created: 2011
related:
  - format/disk/raw
detect:
  any:
    - offset: 0
      type: string
      value: "AARUFRMT"
    - offset: 0
      type: string
      value: "DICMFRMT"
---

# AaruFormat (Aaru Disk Image)

AaruFormat is the native disk image format of Aaru (formerly DiscImageChef),
a data preservation suite created by Natalia Portillo. It is designed for
archival-quality imaging of virtually any media type — floppies, hard drives,
optical discs, tapes, and flash devices.

## Characteristics

- Block-level deduplication
- LZMA compression (FLAC for audio CD sectors)
- Comprehensive metadata (media type, geometry, dumping hardware info)
- Optical disc track/session layout
- Tape file/partition info
- Flux captures (raw magnetic flux data)
- Checksums for data integrity
- Sparse storage

## Structure

The file starts with an 8-byte magic identifier:

| Magic | ASCII | Format |
|-------|-------|--------|
| `0x544D524655524141` | `AARUFRMT` | Current (Aaru) |
| `0x544D52464D434944` | `DICMFRMT` | Legacy (DiscImageChef) |

Both magics are stored as little-endian uint64 but read as ASCII strings
left-to-right.

The header is followed by:
- Format version and flags
- Media information (type, model, serial, firmware)
- Data block index (offsets to deduplicated/compressed blocks)
- Metadata blocks (JSON)
- Checksum blocks

## Versions

| Version | Notes |
|---------|-------|
| 1 | Original C# implementation |
| 2 | Current, C implementation, extended headers |

## File Extension

`.aaruf` (formerly `.dicf`)

## Media Support

AaruFormat can image media that most tools cannot:
- Copy-protected floppies (flux-level capture)
- Optical discs with subchannel data
- Tape drives with file marks and partitions
- CompactFlash, SD cards with geometry info
- Devices with bad sectors (recorded and mapped)

## References

- [Aaru GitHub](https://github.com/aaru-dps/Aaru)
- [AaruFormat spec](https://github.com/aaru-dps/AaruFormat)
