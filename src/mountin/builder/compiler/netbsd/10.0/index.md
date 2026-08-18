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
execution_env:
  BUILD_JOBS: ${BUILD_JOBS}
build_requires:
  - sources/netbsd-10.0-src.tgz
  - sources/netbsd-10.0-syssrc.tgz
  - sources/netbsd-10.0-sharesrc.tgz
  - sources/netbsd-10.0-gnusrc.tgz
---

# NetBSD 10.0 Compiler

Cross-compiler for NetBSD 10.0, built using NetBSD's build.sh. The incremental
tool and library objects stay in the host build cache. The published image
contains only the cross-tools, target headers, the libraries used by mountin,
and amd64 boot blocks; appliance programs are built separately from explicitly
declared sources. The cross-compiler builds only its C frontend and does not
produce x86 multilib or shared target libraries because the appliance has no
32-bit or dynamically linked programs. CTF generation is disabled because the
published appliance does not ship CTF debugging data.

Consumers inherit `CC`, `AR`, `STRIP`, and `NETBSD_SYSROOT`. The compiler
wrapper supplies the target sysroot for both compilation and linking, so normal
build systems do not need to know the NetBSD tools or object-tree layout.

Architecture mapping:
- x86_64 → amd64/x86_64
- aarch64 → evbarm/aarch64
