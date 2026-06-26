---
format: fs/prodos
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.prodos
---

# ProDOS Test Image

An Apple ProDOS volume on a plain 800K (1600 x 512-byte block) ProDOS-order
block image, built by packing the `basic` template tree into a fresh ProDOS
volume. Directories in the template become real ProDOS subdirectories.

The image exists to exercise ProDOS detection and (eventually) a ProDOS
filesystem reader, and to wrap in a `disk/2img` container for the end-to-end
chaining proof. `mkprodos.py` is a general-purpose ProDOS mkfs
(`mkprodos.py OUTPUT.po SRC_DIR`), not specific to this fixture, and verifies
each image by reading the whole tree back before writing it out.
