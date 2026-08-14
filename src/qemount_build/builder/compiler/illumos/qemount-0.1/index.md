---
title: illumos qemount 0.1 Build Toolbox
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-illumos:
    provides:
      - docker:builder/compiler/illumos/qemount-0.1
env:
  BUILDER: builder/compiler/illumos
  JOBS: ${JOBS}
requires:
  - docker:${BUILDER}
build_requires:
  - sources/binutils-2.46.1.tar.bz2
  - sources/illumos-gate-qemount-0.1.tar.gz
  - bin/${BUILD_ARCH}-linux-gnu/dmake
  - bin/${BUILD_ARCH}-linux-gnu/lib/libmakestate.so.1
  - bin/${BUILD_ARCH}-linux-gnu/lib/64/libelf.so.1
---

# illumos qemount 0.1 Build Toolbox

Linux-hosted compiler, native build tools and target sysroot for the illumos
revision tagged `qemount-0.1`. The image builds the exact headers, startup
objects, runtime linker and libraries used by appliance programs.
