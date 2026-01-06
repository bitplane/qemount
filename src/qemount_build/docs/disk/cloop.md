---
title: cloop
created: 1999
related:
  - disk/raw
  - fs/squashfs
detect:
  any:
    - offset: 0
      type: string
      length: 14
      value: "#!/bin/sh\n#V2"
      name: "cloop v2 script"
    - offset: 128
      type: be32
      value: 0x00000001
      name: "cloop block size marker"
---

# Compressed Loop (cloop)

Cloop is a compressed loopback block device format, commonly used for live CD
distributions like Knoppix. It provides read-only compressed disk images.

## Characteristics

- Read-only
- Block-level compression (zlib, lzo, lz4, xz)
- Used for live Linux CDs
- Smaller than squashfs for some use cases
- Random access via block index

## History

Developed by Klaus Knopper for Knoppix, cloop allowed fitting a full Linux
system onto a CD by compressing the filesystem image. Each block is compressed
independently, allowing random access.

## Structure

- Header with block size and count
- Block offset table (index)
- Compressed blocks

Version 2 includes a shell script header for self-extraction.

## Header Fields

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 128 | Optional script header |
| 0x80 | 4 | Block size |
| 0x84 | 4 | Number of blocks |
| 0x88 | ... | Block offset table |

## Detection

Often starts with a shell script header `#!/bin/sh` followed by version marker.
The actual cloop data may follow after the script portion.

## QEMU Support

QEMU has read-only cloop support:

```sh
qemu-system-x86_64 -drive file=disk.cloop,format=cloop,readonly=on
```

## Tools

```sh
# Create cloop (Linux, requires cloop-utils)
create_compressed_fs image.iso image.cloop

# Extract cloop
extract_compressed_fs image.cloop image.iso
```

## Modern Alternatives

For new projects, consider:
- **squashfs**: Better compression, more features
- **erofs**: Enhanced read-only filesystem
- **compressed qcow2**: If VM-specific features needed

Cloop is mainly encountered in legacy live CD images.
