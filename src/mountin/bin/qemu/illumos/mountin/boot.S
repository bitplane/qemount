.section .text
.code32

#ifndef DBOOT_ENTRY
#error DBOOT_ENTRY must be derived from the illumos kernel ELF
#endif

/*
 * QEMU's Multiboot loader uses the host-side kernel path as the kernel command
 * line. The launcher exposes the published kernel through an xplatform/...
 * alias, so replacing its first byte produces the canonical /platform/... path
 * of the real ELF in the boot filesystem while retaining QEMU's command-line
 * allocation and any arguments which follow it. The rootfs type is supplied by
 * QEMU's native Multiboot module-argument syntax.
 *
 * boot-build.sh places the original ELF so its first loadable segment lands at
 * the physical address declared by that ELF and derives DBOOT_ENTRY from its
 * dboot_image symbol rather than assuming a particular link address.
 */
.long 0x1badb002
.long 0x00010003
.long 0xe4514ffb
.long 0x00bff000
.long 0x00bff000
.long 0
.long 0
.long 0x00bff020

.global _start
_start:
	mov 16(%ebx), %ecx
	movb $'/', (%ecx)

	mov $DBOOT_ENTRY, %ecx
	jmp *%ecx
