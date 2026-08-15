---
title: RPM
created: 1995
detect:
  - offset: 0
    type: be32
    value: 0xedabeedb
---

# RPM (Red Hat Package Manager)

RPM was created by Erik Troan and Marc Ewing at Red Hat in 1995. It is
the standard package format for Red Hat, Fedora, CentOS, SUSE, and many
other Linux distributions. An RPM contains a cpio archive of files plus
metadata headers.

## Characteristics

- Lead + signature + header + payload structure
- Payload is a compressed cpio archive (gzip, bzip2, xz, or zstd)
- Rich dependency metadata (requires, provides, conflicts, obsoletes)
- Scriptlets (pre/post install/uninstall scripts)
- Digital signatures (GPG)
- Delta RPM support (drpm)

## Structure

```
Lead (96 bytes):
  Offset  Size  Field
  0       4     Magic (0xEDABEEDB)
  4       1     Major version
  5       1     Minor version
  6       2     Type (0=binary, 1=source)
  8       2     Architecture
  10      66    Name
  76      2     OS
  78      2     Signature type
  80      16    Reserved

Signature header (16-byte aligned)
Header (package metadata)
Payload (compressed cpio)
```

## File Extension

`.rpm`, `.src.rpm` (source packages)

## References

- [RPM.org](https://rpm.org/)
- Magic `0xEDABEEDB` — spells nothing, just a distinctive constant
