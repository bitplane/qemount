---
title: illumos qemount appliance
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/system/xplatform/i86pc/kernel/amd64/unix
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/system/rootfs.iso
requires:
  - docker:builder/disk/guest
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/boot/xplatform/i86pc/kernel/amd64/unix
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/rootfs.iso
---

# illumos qemount appliance

Minimal source-built illumos appliance for QEMU. The kernel boots the HSFS
root image as its Multiboot initrd, discovers attached block devices, mounts
supported volumes beneath `/mnt`, and serves that namespace over its second
serial port using simple9p.

Run QEMU from the output directory with the kernel at
`xplatform/i86pc/kernel/amd64/unix` and the Multiboot module argument
`-initrd "rootfs.iso type=rootfs"`. The first serial port is the console; the
second carries 9P. Attach the input image as a virtio block device.
