---
title: qemount init for Darwin
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-darwin: {}
env:
  BUILDER: builder/compiler/puredarwin/17.4
requires:
  - docker:${BUILDER}
provides:
  - bin/${OUTPUT_ARCH}-darwin/qemount-init
---

# qemount init for Darwin

Minimal libSystem-only init for the PureDarwin appliance. It identifies the
single attached image, mounts HFS or HFS+ read-only, configures the kernel
console as a byte stream and starts the serial 9P adapter.
