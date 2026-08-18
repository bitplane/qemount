---
title: AROS PC i386 mountin Appliance
requires:
  - guest/${TARGET_ARCH}-aros/2026-07-30/aros.iso
  - bin/${TARGET_ARCH}-aros/9d
provides:
  - bin/qemu/${TARGET_ARCH}-aros/2026-07-30/aros.iso
---

# AROS PC i386 mountin Appliance

Purpose-built AROS ISO with 9d serving all mounted DOS volumes beneath a
synthetic root over the second serial unit. The image is assembled from an
explicit runtime allowlist and a dependency-closed GRUB module set instead of
carrying the AROS Live CD. It retains the native bootstrap, disk discovery,
AFFS, FAT, PFS and SFS handlers, and the libraries required by 9d.

The resulting guest is roughly 3 MiB. The base operating system and guest
program remain separate build outputs, while the matching SDK lives in the
compiler toolbox used to build those programs.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest; transports without that constraint retain their normal
request concurrency.

## Storage capabilities

The allowlisted guest contains AROS's GPT, MBR, EBR, and RDB partition-table
readers. These are capabilities of `partition.library`; a reader is not marked
as working in mountin until an image has also completed discovery, mounting,
and traversal over 9P.

| Partition table | Included | mountin proof |
| --------------- | -------- | -------------- |
| MBR             | Yes      | FAT16 and FAT32 primary partitions |
| EBR             | Yes      | Not yet tested |
| GPT             | Yes      | Not yet tested |
| RDB             | Yes      | Real Amiga disk plus OFS, FFS, SFS, and PFS experiments |

The filesystem package supplies five resident handlers:

| Handler         | Formats advertised by AROS | mountin proof |
| --------------- | -------------------------- | -------------- |
| `afs-handler`   | DOS0-DOS7 and muFS variants | DOS0 OFS and DOS3 FFS |
| `fat-handler`   | FAT12, FAT16, FAT32         | FAT16 and FAT32 in MBR |
| `pfs3-handler`  | PFS3 RDB partitions         | PFS write/read and 9P traversal |
| `sfs-handler`   | SFS0                        | SFS RDB write/read and discovery |
| `cdrom-handler` | ISO 9660, Rock Ridge, Joliet; detects High Sierra | Boot ISO over 9P |

High Sierra detection is present, but `Open_Volume()` has no corresponding
initialisation path, so detected discs cannot currently be opened. The CD
handler also contains HFS code, but its own source notes that the on-disk
structures lack endian conversion and are probably broken on little-endian
targets. AROS builds an optional `ntfs-handler` into `Storage`, but it is not
part of the resident filesystem package or this guest. These are therefore
recorded as candidates rather than advertised i386 mountin capabilities.
