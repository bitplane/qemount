---
title: DMG
created: 2000
related:
  - format/disk/raw
  - format/fs/hfsplus
  - format/fs/apfs
detect:
  any:
    - offset: -512
      type: string
      length: 4
      value: "koly"
      name: "DMG trailer"
    - offset: 0
      type: be32
      value: 0x7801730d
      name: "DMG zlib"
---

# Apple Disk Image (DMG)

DMG is Apple's native disk image format for macOS, used for software
distribution and disk backups. It's essentially a container for a filesystem
image with optional compression and encryption.

## Characteristics

- Contains HFS+, APFS, or other filesystems
- Multiple compression options (zlib, bzip2, lzfse, lzma)
- AES-128 or AES-256 encryption
- Segmented files for large images
- UDIF (Universal Disk Image Format) structure
- Read-only in QEMU

## Types

- **UDIF**: Modern format with XML plist and koly trailer
- **NDIF**: Legacy format (pre-OS X)
- **Sparse**: Read-write, grows as needed
- **Sparse bundle**: Directory of small files

## Structure

UDIF format:
- Data fork (compressed blocks)
- XML plist (block map, checksums)
- Koly trailer (512 bytes at end)

## Koly Trailer

| Offset | Size | Field                    |
|--------|------|--------------------------|
| 0x00   | 4    | Signature ("koly")       |
| 0x04   | 4    | Version                  |
| 0x08   | 4    | Header size              |
| 0x0C   | 4    | Flags                    |
| 0x10   | 8    | Running data fork offset |
| 0x18   | 8    | Data fork offset         |
| 0x20   | 8    | Data fork length         |
| 0x28   | 8    | Rsrc fork offset         |
| 0x30   | 8    | Rsrc fork length         |
| 0x38   | 4    | Segment number           |
| 0x3C   | 4    | Segment count            |
| 0x40   | 16   | Segment ID               |
| 0x50   | 4    | Data checksum type       |
| 0x54   | 4    | Data checksum size       |
| 0x58   | 128  | Data checksum            |
| 0xD8   | 8    | XML offset               |
| 0xE0   | 8    | XML length               |

## Detection

The "koly" signature at 512 bytes from the end of the file identifies a UDIF
DMG. Some DMG files may also start with compression signatures.

## QEMU Support

QEMU has read-only DMG support:

```sh
qemu-system-x86_64 -drive file=disk.dmg,format=dmg,readonly=on
```

## Tools

```sh
# macOS: Create DMG
hdiutil create -size 100m -fs HFS+ -volname "Volume" disk.dmg

# Convert DMG to raw
qemu-img convert -f dmg -O raw disk.dmg disk.img

# Linux: Mount with dmg2img + loop
dmg2img disk.dmg disk.img
```

## Limitations

- QEMU support is read-only
- Encrypted DMGs require decryption first
- Some compression types may not be supported
