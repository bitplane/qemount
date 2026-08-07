---
format: fs/v6
requires:
  - docker:builder/disk/research-unix
build_requires:
  - bin/qemu/x86_64-9front/qemount/system/9front.iso
  - data/templates/basic.tar
env:
  RESEARCH_UNIX_FORMAT: v6
provides:
  - data/fs/basic.v6
---

# Research Unix V6 Test Image

Minimal raw V6 filesystem containing every entry from the standard template
that the format can represent. Symbolic links are omitted because V6 has no
symbolic-link inode type, and names longer than fourteen bytes are truncated as
they were by the historical directory format. The generated image is traversed
using 9front's read-only `v6fs` server.
