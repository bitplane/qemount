---
title: 9d for AROS
requires:
  - sources/9d-0.7.1.tar.xz
provides:
  - bin/${TARGET_ARCH}-aros/9d
---

# 9d for AROS

Socket-free 9d build for AROS. Its platform adapter snapshots mounted DOS
volumes and exports them beneath a synthetic `/`. It is compiled with the SDK
contained in the AROS compiler toolbox.
