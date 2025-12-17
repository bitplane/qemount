---
title: High Sierra
created: 1986
discontinued: 1988
related:
  - fs/iso9660
  - fs/udf
detect:
  - offset: 0x8001
    type: string
    value: "CDROM"
---

# High Sierra Format (HSF)

High Sierra Format was developed by a group of industry representatives
meeting at the High Sierra Hotel in Lake Tahoe in 1985, published in 1986.
It was the precursor to ISO 9660 and established the standard for CD-ROM
filesystems.

## Characteristics

- Original CD-ROM filesystem standard
- 2048-byte logical sectors
- 8.3 filename format (like DOS)
- Directory hierarchy
- Path table for fast access
- Maximum file size: 4 GB (theoretical)
- Superseded by ISO 9660 in 1988

## Structure

- Volume descriptor at sector 16
- "CDROM" signature at offset 0x8001
- Root directory record
- Path table (optional)
- Directory records with extent info
- Little-endian and big-endian fields

## vs ISO 9660

| Feature | High Sierra | ISO 9660 |
|---------|-------------|----------|
| Year | 1986 | 1988 |
| Signature | "CDROM" | "CD001" |
| Standard | De facto | ISO |
| Extensions | Limited | Rock Ridge, Joliet |

High Sierra was standardized as ISO 9660 with minor modifications.
The formats are nearly identical, and most systems handle both.

## Historical Significance

High Sierra was the first widely-adopted CD-ROM filesystem standard,
enabling the CD-ROM revolution of the late 1980s. The "High Sierra"
name comes from the hotel where representatives from Apple, DEC,
Hitachi, Microsoft, Philips, Sony, and others met to create it.

## Platform Support

- **Linux**: Supported via ISO 9660 driver (auto-detects)
- **Windows**: Native support
- **macOS**: Native support
- **NetBSD**: Via cd9660

## Modern Usage

High Sierra discs are rare today. Most CD/DVD/Blu-ray uses ISO 9660
with extensions (Rock Ridge for UNIX, Joliet for Windows long names).
The format is mainly of historical interest, though Linux and other
systems still support it for compatibility with old discs.
