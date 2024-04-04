.globl _start
.type _start, @function
.globl entry
.type entry, @function
_start:
	#mov -4(%ebp),%eax
	pop %rax
	mov %rax,argc(%rip)
	mov %rax,%rdi
	pop %rax
	mov %rax,argv(%rip)
	cmp $1,%rdi
	jg endif
	mov $1,%rdi
	call usage
	jmp _exit
endif:
	
	mov $0,%rdi
	jmp _exit

usage:
	lea help0(%rip),%rdi
	mov $help0l,%rsi
	call write

	mov argv(%rip),%rdi
	push %rdi
	call strlen
	pop %rdi
	mov %rax,%rsi
	call write

	lea help1(%rip),%rdi
	mov $help1l,%rsi
	call write

	ret

# rdi - buf
# -> rax - len
strlen:
	mov %rdi,%rsi
	xor %rax,%rax
	repne scasb
	sub %rsi,%rdi
	mov %rdi,%rax
	ret

# rdi - buf
# rsi - len
write:
	push %rdi
	push %rsi
	pop %rdx
	pop %rsi
	mov $1,%rax
	mov $1,%rdi
	syscall
	ret
help0:
	.ascii "Usage: "
	.set help0l, .-help0
help1:
	.ascii " regex0 [regex1 ...]\nstdout: NUL-separated list of matching strings\n"
	.set help1l, .-help1
_exit:
	mov $0x3c,%rax
	syscall
	ret
entry:
	ret

.bss
argc:
	.zero 8
argv:
	.zero 8
buf:
	.zero 65536
