---
format: fs/hu-basic
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.hu-basic
---

# Hu-BASIC Test Image

A Sharp X1 Hu-BASIC filesystem on a plain 2D floppy image (327,680 bytes), built
by packing the `basic` template files into a fresh Hu-BASIC directory. Each
template file becomes a binary-type Hu-BASIC file.

The image exists to exercise Hu-BASIC detection and (eventually) a Hu-BASIC
filesystem reader. `mkhubasic.py` is a general-purpose Hu-BASIC mkfs
(`mkhubasic.py OUTPUT.2d INPUT...`), not specific to this fixture, and verifies
each image by reading it back before writing it out.
