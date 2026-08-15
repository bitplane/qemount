---
title: 2IMG / 2MG (Apple IIgs / Mac disk image)
created: c. 1998
system: Apple IIgs, early Macintosh (emulators & utilities)
extensions: [".2mg", ".2img"]
aliases:
  - 2IMG
  - 2MG
  - Universal Disk Image
related:
  - format/disk/apple-gcr
  - format/disk/apple2
  - format/disk/diskcopy42
  - format/fs/prodos
  - format/fs/hfs
  - format/disk/raw
detect:
  any:
    # ASCII "2IMG" at offset 0. The header carries explicit data-offset and
    # data-length fields, so the magic alone is the robust signature.
    - offset: 0
      type: string
      value: "2IMG"
---

# 2IMG / 2MG (Apple IIgs / Mac disk image)

2IMG (also written `.2mg`) is a small, self-describing **header-strip container**
for Apple II / IIgs / early-Macintosh disk images. It was introduced by the
Apple IIgs emulator community (Bernie ][ the Rescue, XGS, Sweet16, CiderPress,
etc.) so a raw sector dump could travel with the few facts a loader needs:
which sector order it is in, how many ProDOS blocks it holds, and where the
data begins. Strip the 64-byte header and what remains is an ordinary raw disk
image, which is why it sits in `disk/` rather than being a format of its own
on the surface.

## Header

A fixed header sits at offset 0. All multi-byte fields are little-endian.

| Offset | Size | Field |
|--------|------|-------|
| `0x00` | 4 | Magic `2IMG` |
| `0x04` | 4 | Creator ID (e.g. `XGS!`, `CdrP`, `B2TR`) |
| `0x08` | 2 | Header length (normally `0x0040` = 64) |
| `0x0A` | 2 | Version |
| `0x0C` | 4 | Data format: `0` = DOS 3.3 order, `1` = ProDOS order, `2` = NIB |
| `0x10` | 4 | Flags (bit 31 = locked; bit 8 = DOS volume# present; bits 0–7 = volume#) |
| `0x14` | 4 | ProDOS block count (512-byte blocks) |
| `0x18` | 4 | Offset to disk data |
| `0x1C` | 4 | Length of disk data, in bytes |
| `0x20` | 4 | Comment offset |
| `0x24` | 4 | Comment length |
| `0x28` | 4 | Creator-data offset |
| `0x2C` | 4 | Creator-data length |
| `0x30` | 16 | Reserved (zero) |

The disk data is the only part we need: the container yields the
`[data-offset, data-offset + data-length)` region as a single raw-disk child,
and the recursion engine then detects whatever is inside it.

## What the payload bottoms out in

The `data format` field at `0x0C` says how the sectors are arranged:

- **ProDOS order (`1`)** — the common case for 800K IIgs / Mac images. The
  bytes are already in logical block order, so the raw child detects directly
  as [HFS](../fs/hfs) (Macintosh) or [ProDOS](../fs/prodos) (IIgs) and is
  mountable without further work.
- **DOS 3.3 order (`0`)** — 5.25" images whose sectors follow the DOS 3.3 skew.
  The header is still stripped, but reading the filesystem would need a sector
  deinterleave first (a DOS 3.3 / ProDOS-order permutation); that is tracked
  with the other Apple sector-order work and not done here.
- **NIB (`2`)** — nibblised GCR; the sliced data is a raw nibble stream, not
  decoded sectors. Decoding it is the same GCR problem as [apple2](apple2) /
  [apple-gcr](apple-gcr) and is deferred.

So the driver is a pure header-strip; the order/encoding distinctions are a
property of the raw child, handled (or deferred) one layer down.

## Detection

The file begins with the 4-byte ASCII magic `2IMG` at offset 0. Because the
header records the data offset and length explicitly, the magic alone is a
robust signature; the `detect:` rule keys on it. (Confirmed by the original
2IMG/2MG specification and by CiderPress / MAME's loader.)

## References

- MAME loader: [`src/lib/formats/ap_dsk35.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ap_dsk35.cpp)
- [2IMG / 2MG disk image format specification](https://gswv.apple2.org.za/a2zine/Docs/DiskImage_2MG_Info.txt)
- [CiderPress documentation — 2MG](https://a2ciderpress.com/)
