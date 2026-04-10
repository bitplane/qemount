---
title: WIM
created: 2004
detect:
  - offset: 0
    type: string
    value: "MSWIM\x00\x00\x00"
---

# WIM (Windows Imaging Format)

WIM was created by Microsoft around 2004 for Windows Vista deployment.
It is a file-based disk imaging format — unlike sector-based formats,
WIM captures individual files, enabling single-instancing (deduplication)
across multiple images in one file. Used for Windows installation media,
recovery, and enterprise deployment.

## Characteristics

- File-based (not sector-based) imaging
- Single-instancing — identical files stored once across images
- Multiple images per WIM file (e.g. Home, Pro, Enterprise)
- LZX, XPRESS, or LZMS compression
- Capture and apply to different partition sizes
- Integrity table (SHA-1 checksums)
- Split WIM support (.swm)
- Solid compression (ESD format, .esd)

## Structure

```
Header (208 bytes):
  Offset  Size  Field
  0       8     Magic ("MSWIM\x00\x00\x00")
  8       4     Header size
  12      4     Version
  16      4     Flags
  20      4     Compressed chunk size
  24      16    WIM GUID
  40      2     Part number
  42      2     Total parts
  44      4     Image count
  48      24    Offset table reference
  72      24    XML data reference
  96      24    Boot metadata reference
  120     4     Boot index
  124     24    Integrity table reference
  148     60    Reserved
```

## Variants

| Extension | Format |
|-----------|--------|
| `.wim` | Standard WIM |
| `.swm` | Split WIM |
| `.esd` | Solid-compressed WIM (LZMS) |
| `.ppkg` | Provisioning package |

wimlib's pipable format uses `WLPWM\x00\x00\x00` magic.

## File Extension

`.wim`

## References

- [wimlib](https://wimlib.net/) — open source WIM library
- Every Windows install.wim since Vista
