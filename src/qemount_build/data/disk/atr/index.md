---
format: disk/atr
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.atari-dos
provides:
  - data/disk/basic.atr
---

# ATR Test Image

An ATR container wrapping the Atari DOS test volume (`data/fs/basic.atari-dos`)
in a 16-byte ATR header. It exists to prove the `disk/atr` driver end-to-end:
the driver recognises the `0x0296` magic, strips the header, and the recursion
engine then sees the raw Atari DOS sector image inside (i.e. `disk/atr -> raw`,
and `disk/atr -> fs/atari-dos` once an Atari DOS detect rule is added).
