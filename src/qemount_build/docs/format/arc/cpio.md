---
title: cpio
created: 1977
related:
  - format/arc/tar
detect:
  any:
    - offset: 0
      type: string
      value: "070707"
      name: odc_ascii
    - offset: 0
      type: string
      value: "070701"
      name: newc
    - offset: 0
      type: string
      value: "070702"
      name: newc_crc
    - offset: 0
      type: le16
      value: 0x71c7
      name: binary_le
    - offset: 0
      type: be16
      value: 0xc771
      name: binary_be
---

# cpio (Copy In/Out)

cpio was created at AT&T in 1977, predating tar. It's still used for
Linux initramfs, RPM packages, and some backup systems.

## Characteristics

- Multiple format variants
- Simpler than tar
- Used for Linux initramfs
- RPM package payload format
- Can read from file list on stdin

## Formats

| Format | Magic | Notes |
|--------|-------|-------|
| Binary (old) | 0x71c7 | Original, obsolete |
| odc | "070707" | POSIX.1 portable |
| newc | "070701" | SVR4, most common |
| newc+crc | "070702" | With CRC checksum |

## Structure (newc format)

**Header (110 bytes ASCII):**
```
Offset  Size  Field
0       6     Magic "070701"
6       8     Inode (hex)
14      8     Mode (hex)
22      8     UID (hex)
30      8     GID (hex)
38      8     Nlink (hex)
46      8     Mtime (hex)
54      8     Filesize (hex)
62      8     Dev major (hex)
70      8     Dev minor (hex)
78      8     Rdev major (hex)
86      8     Rdev minor (hex)
94      8     Namesize (hex)
102     8     Checksum (hex)
```

Followed by filename (padded to 4 bytes), then file data (padded to 4 bytes).

## Archive Terminator

Archive ends with a special entry named "TRAILER!!!".

## Use Cases

- **initramfs**: Linux initial ramdisk
- **RPM**: Package payload (compressed)
- **find | cpio**: Backup pipelines
- **pax**: POSIX replacement for both tar and cpio
