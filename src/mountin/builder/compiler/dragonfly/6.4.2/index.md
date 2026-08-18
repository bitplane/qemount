---
title: DragonFly BSD 6.4.2 Compiler
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-dragonfly:
    provides:
      - docker:builder/compiler/dragonfly/6.4.2/x86_64
env:
  BUILDER: builder/compiler/dragonfly
execution_env:
  BUILD_JOBS: ${BUILD_JOBS}
requires:
  - docker:${BUILDER}
build_requires:
  - sources/dragonfly-6.4.2.tar.gz
---

# DragonFly BSD 6.4.2 Compiler

Experimental Linux-hosted source build of the DragonFly BSD base system. Both
x86_64 and AArch64 Linux hosts build DragonFly's x86_64 target; DragonFly does
not provide an AArch64 target. The build deliberately uses only native Linux
host tools and the upstream source tree so host assumptions are exposed rather
than hidden by a binary bootstrap.
