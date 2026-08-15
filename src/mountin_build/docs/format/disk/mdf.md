---
title: MDF (Alcohol 120%)
created: 2002
related:
  - format/disk/nrg
  - format/disk/cdi
---

# MDF (Media Descriptor File)

MDF is the disc image format used by Alcohol 120%, created by Alcohol
Soft around 2002. It was widely used for backing up copy-protected CDs
and DVDs. The format stores raw sector data in the `.mdf` file with
metadata in a companion `.mds` sidecar file.

## Characteristics

- Raw sector data (2048 or 2352 bytes per sector)
- Supports CD and DVD media
- Copy protection preservation (subchannel data, raw mode)
- Requires MDS sidecar for track/session layout
- No built-in compression

## Detection

MDF has no magic number — the data file is raw sector data with no
header. The companion `.mds` file contains the metadata but its format
is undocumented and proprietary. Detection would require finding the
MDS file or identifying raw sector patterns.

## Structure

The `.mdf` file is a raw dump of disc sectors. Track boundaries, session
info, and sector mode are described in the `.mds` file.

The `.mds` file format is proprietary and partially reverse-engineered.
It contains:
- Session descriptors
- Track descriptors with mode, sector size, and start offsets
- Subchannel data locations

## File Extensions

| Extension | Purpose |
|-----------|---------|
| `.mdf` | Raw sector data |
| `.mds` | Metadata descriptor |

## References

- Alcohol 120% / Alcohol Soft
- Various MDS parsers exist in emulator source code
