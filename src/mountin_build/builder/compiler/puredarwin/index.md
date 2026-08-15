---
title: PureDarwin Build Environment
provides:
  - docker:builder/compiler/puredarwin
---

# PureDarwin Build Environment

Linux-hosted Clang/LLVM environment for bootstrapping PureDarwin's vendored
Mach-O tools and building the x86_64 system. PureDarwin source and build state
remain outside the image so source updates do not rebuild the tool container.
