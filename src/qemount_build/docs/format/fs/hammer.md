---
title: HAMMER
created: 2008
related:
  - format/fs/hammer2
detect:
  any:
    - offset: 0
      type: le64
      value: 0xc8414d4dc5523031
      then:
        - offset: 0x98
          type: le32
          name: version
    - offset: 0
      type: le64
      value: 0x313052c54d4d41c8
      then:
        - offset: 0x98
          type: be32
          name: version
---

# HAMMER Filesystem

HAMMER is a 64-bit copy-on-write filesystem introduced by DragonFly BSD 2.0.
It was designed for large storage systems and supports snapshots, historical
data retention, checksums and multi-volume filesystems.

## Structure

The root volume starts with a volume header. Its 64-bit signature is the bytes
`31 30 52 c5 4d 4d 41 c8`; the reverse-endian form is also valid. The header
contains the filesystem identifier, label, version, allocation statistics and
block maps.

## Platform Support

- **DragonFly BSD**: Native read/write support
- **Linux**: No in-kernel support
- **FreeBSD**: No in-kernel support
- **NetBSD**: No in-kernel support

HAMMER2 replaced HAMMER as DragonFly BSD's default filesystem in version 5.0.
