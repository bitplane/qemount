.section .text
.code32

/*
 * QEMU's Multiboot loader uses the host-side kernel path as the kernel command
 * line. The appliance stores this wrapper under xplatform/... so changing its
 * first byte gives dboot the canonical /platform/... path of the real ELF in
 * the boot filesystem. The rootfs type is supplied by QEMU's native Multiboot
 * module-argument syntax.
 *
 * The original ELF begins at file offset 0xea8. Loading this wrapper at the
 * page-aligned address 0xbff000 places the ELF at its patched load address
 * 0xbffea8 and lets QEMU page-align the rootfs module which follows it.
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

	mov $0xc00060, %ecx
	jmp *%ecx
