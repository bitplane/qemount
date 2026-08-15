---
title: PAQFS
related:
  - format/fs/sacfs
  - format/fs/flashfs
detect:
  any:
    - offset: 0
      type: be32
      value: 0x529ab12b
      then:
        - offset: 4
          type: be16
          value: 1
          name: version
        - offset: 6
          type: be16
          name: block_size
    - offset: 0
      type: be16
      value: 0x25a9
      then:
        - offset: 2
          type: be16
          value: 1
          name: version
        - offset: 4
          type: be32
          name: block_size
---

# PAQFS

PAQFS is a compressed, read-only Plan 9 filesystem intended for compact
standalone images such as boot filesystems and flash-ROM contents. `mkpaqfs`
packs a directory tree into one file; `paqfs` verifies and serves that file over
9P.

## Structure

All integers are big-endian. The 44-byte header contains the signature, format
version, block size, creation time and a 32-byte label. The normal header stores
block sizes below 64 KiB in 16 bits. The large-header form uses a second magic
and a 32-bit block-size field.

Filesystem data is split into directory, file-data and pointer blocks. Each
block has a type, encoding, stored size and Adler-32 checksum. Blocks may be
stored verbatim or independently compressed with DEFLATE. A trailer records the
root block offset and a SHA-1 digest covering the preceding image.

Block sizes may range from 512 bytes to 512 KiB; the default is 4096 bytes.

## References

- [paqfs(4)](http://man.9front.org/4/paqfs)
- [mkpaqfs(8)](http://man.9front.org/8/mkpaqfs)

