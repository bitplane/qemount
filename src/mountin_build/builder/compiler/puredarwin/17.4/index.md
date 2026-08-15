---
title: PureDarwin 17.4 Build Toolbox
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-darwin:
    provides:
      - docker:builder/compiler/puredarwin/17.4
env:
  BUILDER: builder/compiler/puredarwin
  JOBS: ${JOBS}
requires:
  - docker:${BUILDER}
build_requires:
  - sources/architecture-268.tar.gz
  - sources/applefilesystemdriver-23.tar.gz
  - sources/applei386pci-6.tar.gz
  - sources/compiler-rt-14.0.6.src.tar.xz
  - sources/dyld-519.2.2.tar.gz
  - sources/libc-1244.30.3.tar.gz
  - sources/libcxx-5.0.0.src.tar.xz
  - sources/libcxxabi-5.0.0.src.tar.xz
  - sources/libdispatch-913.30.4.tar.gz
  - sources/launchd-842.92.1.tar.gz
  - sources/libinfo-517.30.1.tar.gz
  - sources/libm-2026.tar.gz
  - sources/libnotify-172.tar.gz
  - sources/libmalloc-140.40.1.tar.gz
  - sources/libplatform-161.20.1.tar.gz
  - sources/libpthread-301.30.1.tar.gz
  - sources/libresolv-65.tar.gz
  - sources/libsystem-1252.50.4.tar.gz
  - sources/libunwind-5.0.0.src.tar.xz
  - sources/ioatafamily-255.tar.gz
  - sources/ioatablockstorage-130.3.1.tar.gz
  - sources/iopcifamily-320.30.2.tar.gz
  - sources/iostoragefamily-218.30.1.tar.gz
  - sources/hfs-407.30.1.tar.gz
  - sources/puredarwin-17.4.tar.gz
  - sources/syslog-356.50.1.tar.gz
  - sources/xnu-4570.41.2.tar.gz
  - sources/aros-ports/grub-2.12.tar.gz
---

# PureDarwin 17.4 Build Toolbox

Linux-hosted compiler, Darwin 17.4 BaseSystem closure and source-built BIOS
loader used to assemble the PureDarwin appliance. Intermediate target objects
remain in the host build cache; the resulting toolbox image contains the
runtime tree and boot components needed by downstream image builders.

Consumers inherit `CC`, `AR`, `STRIP`, `OBJDUMP`, and `PUREDARWIN_SYSROOT`.
The compiler wrapper selects the x86_64 Darwin 17 target, open-source sysroot,
minimum deployment version and linker, keeping those details out of ordinary
build definitions.
