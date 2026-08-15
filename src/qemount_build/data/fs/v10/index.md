---
format: fs/v10
requires:
  - docker:builder/disk/research-unix
build_requires:
  - bin/qemu/x86_64-9front/11957/9front.iso
  - data/templates/basic.tar
env:
  RESEARCH_UNIX_FORMAT: v10
provides:
  - data/fs/basic.v10
---

# Research Unix V10 Test Image

Minimal raw V10 filesystem containing every entry from the standard template
that its fixed directory format can represent. Symbolic links are omitted and
names longer than fourteen bytes are truncated. The image is traversed using
9front's read-only `v10fs` server.
