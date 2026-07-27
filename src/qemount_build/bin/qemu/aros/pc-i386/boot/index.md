---
title: AROS PC i386 Guest
requires:
  - bin/qemu/${ARCH}-aros/system/aros.iso
  - bin/${ARCH}-aros/simple9p
provides:
  - bin/qemu/${ARCH}-aros/boot/aros.iso
---

# AROS PC i386 Guest

Bootable tiny-variant AROS ISO with simple9p serving all mounted DOS volumes
beneath a synthetic root over the second serial unit. The base operating
system, SDK, and guest program remain separate build outputs so other AROS
integrations can reuse each layer.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest; transports without that constraint retain their normal
request concurrency.
