---
title: AROS qemount development branch
version: qemount
urls:
  - git+https://github.com/bitplane/AROS.git#qemount
provides:
  - sources/aros-qemount.tar.gz
---

# AROS

AROS source from the qemount development branch of the bitplane fork.

This is intentionally a moving development reference while the guest is being
brought up. Force the ISO target to refresh the cached source archive after the
branch changes. Once the guest build is stable, replace this reference with a
dated, immutable qemount tag.
