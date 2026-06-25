---
format: disk/scl
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/disk/basic.scl
---

# SCL Test Image

Sinclair TR-DOS SCL image built by packing the `basic` template files into a
TR-DOS catalogue. Each template file becomes a TR-DOS "Code" file (8-char name,
host extension dropped), loaded at 0x8000.

The image exists to exercise SCL detection and SCL -> TRD unwrapping. `mkscl.py`
is a general-purpose SCL writer (`mkscl.py OUTPUT INPUT...`), not specific to
this fixture.
