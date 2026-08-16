.section .rodata
console:
	.asciz "/devices/pseudo/cn@0:console"
worker:
	.asciz "/sbin/mountin-init"
failure:
	.ascii "mountin: exec init failed\n"
.set failure_size, . - failure

.section .data
.align 8
argv:
	.quad worker
	.quad 0
envp:
	.quad 0

.section .text
.global _start
_start:
	/* PID 1 starts without descriptors. These become stdin, stdout, stderr. */
	mov $3, %r12d
1:
	mov $5, %eax
	lea console(%rip), %rdi
	mov $2, %esi
	xor %edx, %edx
	syscall
	dec %r12d
	jnz 1b

	mov $59, %eax
	lea worker(%rip), %rdi
	lea argv(%rip), %rsi
	lea envp(%rip), %rdx
	syscall

	mov $4, %eax
	mov $2, %edi
	lea failure(%rip), %rsi
	mov $failure_size, %edx
	syscall
2:
	mov $29, %eax
	syscall
	jmp 2b
