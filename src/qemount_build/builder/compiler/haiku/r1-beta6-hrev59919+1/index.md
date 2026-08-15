---
title: Haiku R1 Beta 6 hrev59919+1 Toolbox
build_platforms:
  x86_64-linux: {}
env:
  OUTPUT_ARCH: x86_64
  HAIKU_REVISION: hrev59919+1
build_requires:
  - sources/haiku-r1-beta6-hrev59919+1.tar.gz
provides:
  - docker:builder/compiler/haiku/r1-beta6-hrev59919-1
---

# Haiku Toolbox

Haiku build environment containing the cross-compiler, source tree, matching
cross-development sysroot and compiled objects used by the appliance.

The OCI repository component spells upstream's `hrev59919+1` as
`hrev59919-1`, because `+` is not valid in a repository name.

Source is mounted during build via `build_requires`. The official
toolchain-worker image is currently published for amd64 hosts only.
