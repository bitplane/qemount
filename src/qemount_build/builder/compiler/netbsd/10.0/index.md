---
title: NetBSD 10.0 Compiler
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-netbsd:
    provides:
      - docker:builder/compiler/netbsd/10.0/x86_64
  aarch64-netbsd:
    provides:
      - docker:builder/compiler/netbsd/10.0/aarch64
env:
  JOBS: ${JOBS}
build_requires:
  - sources/netbsd-10.0-src.tgz
  - sources/netbsd-10.0-syssrc.tgz
  - sources/netbsd-10.0-sharesrc.tgz
  - sources/netbsd-10.0-gnusrc.tgz
---

# NetBSD 10.0 Compiler

Cross-compiler for NetBSD 10.0, built using NetBSD's build.sh. The complete
incremental object tree stays in the host build cache. The compiler image only
contains the cross-tools and the sysroot, rescue, device and boot files used by
downstream qemount builds.

Architecture mapping:
- x86_64 → amd64/x86_64
- aarch64 → evbarm/aarch64
