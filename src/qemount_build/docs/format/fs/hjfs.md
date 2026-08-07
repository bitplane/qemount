---
title: hjfs
related:
  - format/fs/cwfs
  - format/fs/gefs
detect:
  - offset: 0
    type: u8
    value: 1
  - offset: 1
    type: le32
    value: 0x6e0de51c
---

# hjfs

hjfs is an experimental 9front filesystem combining a writable filesystem,
cache and archival dump on one partition. It is implemented as a user-space 9P
file server and can initialize an image directly with its `-r` option.

## Structure

The format uses fixed 4096-byte blocks. Every block starts with a one-byte type;
the superblock is type 1 and occupies block zero. Its little-endian payload
begins with magic `0x6e0de51c`, followed by the device size, free-space bounds,
root block and next QID path.

Other block types contain directory entries, indirect block addresses and
24-bit reference counts. Directory entries use 256-byte names, 15 direct block
pointers and four levels of indirect pointers.

hjfs remains explicitly described as work in progress by 9front.

## References

- [hjfs(4)](http://man.9front.org/4/hjfs)
- [hjfs(8)](http://man.9front.org/8/hjfs)

