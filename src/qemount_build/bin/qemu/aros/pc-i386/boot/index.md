---
title: AROS PC i386 Guest
requires:
  - bin/qemu/${ARCH}-aros/system/aros.iso
  - bin/${ARCH}-aros/simple9p
provides:
  - bin/qemu/${ARCH}-aros/boot/aros.iso
---

# AROS PC i386 Guest

Purpose-built AROS ISO with simple9p serving all mounted DOS volumes beneath a
synthetic root over the second serial unit. The image is assembled from an
explicit runtime allowlist and a dependency-closed GRUB module set instead of
carrying the AROS Live CD. It retains the native bootstrap, disk discovery,
AFFS, FAT, PFS and SFS handlers, and the libraries required by simple9p.

The resulting guest is roughly 3 MiB. The base operating system, SDK, and guest
program remain separate build outputs so other AROS integrations can reuse each
layer.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest; transports without that constraint retain their normal
request concurrency.
