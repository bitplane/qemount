---
title: Haiku qemount 2026-07-31
version: qemount-2026-07-31
urls:
  - git+https://github.com/bitplane/Haiku.git#qemount-2026-07-31
provides:
  - sources/haiku-qemount-2026-07-31.tar.gz
---

# Haiku

The proven Haiku integration tree used by the qemount guest, pinned to an
immutable dated tag.[^bugfixes]

[^bugfixes]: Includes fixes for Haiku [ticket #20220](https://dev.haiku-os.org/ticket/20220)
    (`pc_serial`) and [ticket #20221](https://dev.haiku-os.org/ticket/20221)
    (FAT/NTFS file-cache cleanup).
