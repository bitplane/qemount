---
format: pt/gpt
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.hfsplus
provides:
  - data/pt/hfsplus.gpt
---

# GPT HFS Plus Test Image

An Apple HFS Plus partition using its native GPT partition type. This keeps
GPT filesystem validation independent of the larger mixed-filesystem fixture.
