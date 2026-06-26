---
format: disk/apridisk
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/disk/basic.apridisk
---

# APRIDISK Test Image

An APRIDISK (ACT Apricot disk image) container wrapping a 1.44MB FAT12 floppy
built from the standard template. It proves the full chain end-to-end: the
`disk/apridisk` driver reassembles the typed sector records (raw + RLE) into a
flat image and the recursion engine then detects the filesystem inside, i.e.
`disk/apridisk -> fs/fat12`.

The floppy uses Apricot HD geometry (80 tracks x 2 heads x 18 sectors x 512
bytes = 2880 sectors), which is the format's documented maximum. All-identical
sectors are stored RLE-compressed and a leading comment record exercises the
reader's record-skipping path.
