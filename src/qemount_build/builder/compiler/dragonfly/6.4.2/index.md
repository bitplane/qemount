---
title: DragonFly BSD 6.4.2 Compiler
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-dragonfly:
    provides:
      - docker:builder/compiler/dragonfly/6.4.2/x86_64
env:
  BUILDER: builder/compiler/dragonfly
  JOBS: ${JOBS}
requires:
  - docker:${BUILDER}
build_requires:
  - sources/dragonfly-6.4.2.tar.gz
---

# DragonFly BSD 6.4.2 Compiler

Experimental Linux-hosted source build of the DragonFly BSD base system. The
initial target deliberately uses only Linux build tools and the upstream source
tree so host assumptions are exposed rather than hidden by a binary bootstrap.
