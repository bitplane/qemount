---
title: HFE (HxC Floppy Emulator image)
created: 2006
system: HxC Floppy Emulator (generic floppy preservation)
extensions: [".hfe"]
aliases:
  - HxC Floppy Emulator image
  - HxCPICFE
  - HFEv1
  - HFEv2
  - HFEv3
related:
  - format/disk/hxcmfm
  - format/disk/86f
  - format/disk/ipf
  - format/disk/dfi
detect:
  any:
    - offset: 0
      type: string
      value: "HXCPICFE"   # v1 / v2
    - offset: 0
      type: string
      value: "HXCHFEV3"   # v3
---

# HFE (HxC Floppy Emulator image)

HFE is the native image format of the HxC Floppy Emulator, a popular hardware
device (and companion software) that replaces a physical floppy drive with an
SD card, used heavily in retrocomputing and digital preservation. Rather than
storing decoded sectors, HFE stores the raw, head-level **bitstream** for every
track — the magnetic flux transitions as the floppy controller would see them.
This lets it faithfully reproduce arbitrary, non-standard, and copy-protected
disk encodings regardless of the host system, which is why it has become a
common interchange format well beyond the HxC hardware itself.

## Structure

An HFE file is built from 512-byte blocks:

- **File header** (block 0, offsets `0x0000`–`0x01FF`). It opens with an 8-byte
  ASCII signature, then records the format revision, the number of tracks, the
  number of sides (normally 2), the track encoding (e.g. ISO/IBM MFM or FM), the
  sample/bit rate in kHz (commonly 250), the floppy RPM, the drive interface
  mode (e.g. generic Shugart), and the block offset of the track list. Trailing
  flag bytes cover write protection, single-step mode, and alternate track-0
  encodings.
- **Track lookup table** (at offset `0x0200`). One entry per physical track,
  each a pair of little-endian 16-bit values: the offset of that track's data
  (in units of 512-byte blocks) and its length in bytes.
- **Track data** (from `0x0400` onward). Each track block interleaves the two
  sides in alternating 256-byte halves (side 0, then side 1, and so on). The
  bitstream itself is stored least-significant-bit first, where a 1-bit means a
  flux transition and a 0-bit means none.

Because the track tables and per-track flux bitstream are first-class navigable
structure, HFE sits with the other flux/surface image formats in the catalogue
(`86f`, `ipf`, `dfi`) rather than with decoded sector dumps. Its closest sibling
is the HxC `MFM` stream format (`format/disk/hxcmfm`).

## Versions

- **HFEv1** — original format, header signature `HXCPICFE`, revision byte `0`.
- **HFEv2** — same `HXCPICFE` signature, revision byte `1`; adds in-stream
  opcodes (e.g. for setting bit rate or index pulses inside a track).
- **HFEv3** — signature changed to `HXCHFEV3`, revision byte back to `0`;
  redesigned opcode set (3.0, 2017) and later weak-bit support (3.1, 2019).

MAME's loader implements HFEv1/v2 (the `HXCPICFE` family).

## Detection

The HxC2001 published specification and the Library of Congress format registry
agree that an HFE file begins with an 8-byte ASCII signature at offset 0:
`HXCPICFE` for the original v1/v2 streams and `HXCHFEV3` for the redesigned v3
stream. The 9th byte (offset `0x08`) is a format-revision number that
distinguishes v1 (`0`) from v2 (`1`).

## References

- MAME loader: [`src/lib/formats/hxchfe_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hxchfe_dsk.cpp)
- [HFE file format specifications — HxC2001](https://hxc2001.com/floppy_drive_emulator/HFE-file-format.html)
- [SD HxC Floppy Emulator HFE File Format Rev.3.1 (PDF) — HxC2001](https://hxc2001.com/download/floppy_drive_emulator/HxC_Floppy_Emulator_HFE_file_format.pdf)
- [HFE (HxC Floppy Emulator) File Format — Library of Congress](https://www.loc.gov/preservation/digital/formats/fdd/fdd000613.shtml)
