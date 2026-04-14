---
format: arc/lzx
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/arc/basic.lzx
---

# LZX Test Archive

Test archive in Amiga LZX format, built using the `amiga-lzx-cli`
Rust crate (pure-Rust compressor compatible with the original
Amiga LZX 1.21R output).
