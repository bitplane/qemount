---
title: Haiku R1 Beta 6 hrev59919+1
version: r1-beta6-hrev59919+1
urls:
  - git+https://github.com/bitplane/Haiku.git#mountin-2026-08-15
provides:
  - sources/haiku-r1-beta6-hrev59919+1.tar.gz
---

# Haiku

Haiku R1 Beta 6 at hrev59919 with the integration fixes used by qemount,
pinned by an immutable tag on the qemount fork.[^bugfixes]

[^bugfixes]: Includes fixes for Haiku [ticket #20220](https://dev.haiku-os.org/ticket/20220)
    (`pc_serial`) and [ticket #20221](https://dev.haiku-os.org/ticket/20221)
    (FAT/NTFS file-cache cleanup), plus empty exFAT volume-label and embedded
    UDF allocation descriptor handling.
