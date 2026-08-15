.section .text
.code32

/*
 * QEMU's Multiboot loader uses the host-side kernel path as the kernel command
 * line. Point it at the canonical path of the real ELF in the boot filesystem
 * so the published wrapper filename does not become part of the guest ABI. The
 * rootfs type is supplied by QEMU's native Multiboot module-argument syntax.
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
	movl $kernel_path, 16(%ebx)

	mov $0xc00060, %ecx
	jmp *%ecx

kernel_path:
	.asciz "/platform/i86pc/kernel/amd64/unix"
