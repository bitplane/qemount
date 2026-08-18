---
title: illumos 2026-08-13 Build Toolbox
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-illumos:
    provides:
      - docker:builder/compiler/illumos/2026-08-13
env:
  BUILDER: builder/compiler/illumos
execution_env:
  BUILD_JOBS: ${BUILD_JOBS}
requires:
  - docker:${BUILDER}
build_requires:
  - sources/binutils-2.46.1.tar.bz2
  - sources/illumos-gate-mountin-2026-08-15.tar.gz
  - bin/${BUILD_ARCH}-linux-gnu/dmake
  - bin/${BUILD_ARCH}-linux-gnu/lib/libmakestate.so.1
  - bin/${BUILD_ARCH}-linux-gnu/lib/64/libelf.so.1
---

# illumos 2026-08-13 Build Toolbox

Linux-hosted compiler, native build tools and target sysroot for the illumos
generation last synchronized with upstream on 2026-08-13. The source is fetched
from our `mountin-2026-08-15` patch-set tag. The image builds the exact headers,
startup objects, runtime linker and libraries used by appliance programs.

The image exports `CC`, `AR` and `STRIP` for conventional Make builds. Their
versioned command names are `x86_64-illumos-cc`, `x86_64-illumos-ar` and
`x86_64-illumos-strip`; `x86_64-illumos-ld` exposes the corresponding native
link interface.
