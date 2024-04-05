.globl _start
.type _start, @function
.globl entry
.type entry, @function
_start:
	pop %rax
	mov %rax,argc(%rip)
	mov %rax,%rdi
	pop %rax
	mov %rax,argv(%rip)
	cmp $1,%rdi
	jg _start_endif
	mov $1,%rdi
	call usage
	jmp _exit
	_start_endif:
	
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

# rdi - exit code
_exit:
	mov $0x3c,%rax
	syscall
	ret

.include "target/charjmpt.s"

# rdi - where
# rsi - char
#parse_...:

parse_self:
	xor %rax,%rax
	ret

parse_exit:
	mov $1,%rax
	ret


# rdi - regex
# rsi - callback
# rdx - cb data
entry:
	push %rbp
	mov %rsp,%rbp
	sub $48,%rsp
	mov %rsi,-8(%rbp)
	mov %rdx,-16(%rbp)
	mov %rdi,-24(%rbp)
	entry_parse_begin:
		movzbl (%rdi),%ecx
		lea charjmpt(%rip),%r11
		movzx %cl,%r10
		shl $2,%r10
		add %r10,%r11
		movsxd (%r11),%r11
		charjmpt_prej:
		lea charjmpt_prej(%rip),%r10
		add %r10,%r11
		mov %rdi,-32(%rbp)
		call *%r11
		test %rax,%rax
		jnz entry_parse_end
		mov -32(%rbp),%rdi
		inc %rdi
		jmp entry_parse_begin
	entry_parse_end:
	mov %rdi,%rsi
	mov -24(%rbp),%rdi
	sub %rdi,%rsi
	inc %rsi
	mov -16(%rbp),%rdx
	mov -8(%rbp),%r9
	entry_pre_call:
	call *%r9
	mov %rbp,%rsp
	pop %rbp
	ret

.bss
argc:
	.zero 8
argv:
	.zero 8
