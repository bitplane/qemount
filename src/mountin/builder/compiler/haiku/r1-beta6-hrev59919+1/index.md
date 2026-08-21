---
title: Haiku R1 Beta 6 hrev59919+1 Toolbox
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
env:
  MOUNTIN_TARGET_ARCH: x86_64
  MOUNTIN_HAIKU_REVISION: hrev59919+1
build_requires:
  - sources/haiku-r1-beta6-hrev59919+1.tar.gz
  - sources/haiku-buildtools-2026-05-20.tar.gz
requires:
  - docker:builder/compiler/haiku
provides:
  - docker:builder/compiler/haiku/r1-beta6-hrev59919-1
---

# Haiku Toolbox

Haiku build environment containing the cross-compiler, source tree, matching
cross-development sysroot and compiled objects used by the appliance.

Consumers inherit `CC`, `AR`, `STRIP`, `READELF`, and `HAIKU_SYSROOT`. The
compiler wrapper supplies the target sysroot for compilation and linking, so
ordinary build systems do not need to know the cross-toolchain layout.

The OCI repository component spells upstream's `hrev59919+1` as
`hrev59919-1`, because `+` is not valid in a repository name.

The matching Haiku and buildtools sources are mounted during the build. The
x86_64 Haiku cross-toolchain is built natively on either supported Linux host.
