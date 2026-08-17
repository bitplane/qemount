---
format: fs/32v
requires:
  - docker:builder/disk/research-unix
build_requires:
  - guest/x86_64-9front/11957/9front.iso
  - data/templates/basic.tar
env:
  RESEARCH_UNIX_FORMAT: 32v
provides:
  - data/fs/basic.32v
---

# UNIX/32V Test Image

Minimal raw UNIX/32V filesystem containing every entry from the standard
template that the format can represent. Symbolic links are omitted because the
format predates them, and names longer than fourteen bytes are truncated. The
generated image is traversed using 9front's read-only `32vfs` server.
