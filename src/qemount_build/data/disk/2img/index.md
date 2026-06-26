---
format: disk/2img
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.prodos
provides:
  - data/disk/basic.2mg
---

# 2IMG Test Image

A 2IMG / 2MG container wrapping the ProDOS test volume (`data/fs/basic.prodos`)
in ProDOS sector order. It exists to prove the full chain end-to-end: the
`disk/2img` driver strips the 64-byte header and the recursion engine then
detects the ProDOS filesystem inside, i.e. `disk/2img -> fs/prodos`.
