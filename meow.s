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

// rdi - buf
// -> rax - len
strlen:
	mov %rdi,%rsi
	xor %rax,%rax
	repne scasb
	sub %rsi,%rdi
	mov %rdi,%rax
	dec %rax
	ret

// rdi - buf
// rsi - len
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
	.ascii " regex0 [regex1 ...]\n"
	.ascii "writes NUL-separated list of matching strings, one per regex to stdout\n"
	.ascii "uses stack memory, consider disabling the limit if it segfaults\n"
	.set help1l, .-help1

// rdi - exit code
_exit:
	mov $0x3c,%rax
	syscall
	ret

.include "target/charjmpt.s"

.macro eaptrdiff32 ptr=%rax, out=%rax, off=0, tmp=%r11
	eaptrdiff32.\@:
	.if \ptr != \out
	push \ptr
	.endif
	.if \off
	add $\off,\ptr
	.endif
	push \tmp
	mov \ptr,\tmp
	movslq (\tmp),\tmp
	add \tmp,\ptr
	pop \tmp
	.if \ptr != \out
	mov \ptr,\out
	pop \ptr
	.endif
.endm

.macro mkptrdiff32 to=%r11, to_low=%r11d, ptr=%rax, off=0
	mkptrdiff32.\@:
	push \to
	.if \off
	push \ptr
	add $\off,\ptr
	.endif
	sub \ptr,\to
	movl \to_low,(\ptr)
	.if \off
	pop \ptr
	.endif
	pop \to
.endm

// rdi - &state
// rsi - char
// rcx, r8, r9, r10, r11 - scratch
// r12 - real stack (rsp - fake stack)
// -> rax - status
//parse_...:

append_tnode_recurse:


// rdi - &group_alt
// rsi - type
// -> rax - text_node ptr
push_tnode:
	movslq (%rdi),%rcx
	sub $(5*4),%r12
	and $-8,%r12
	movl %esi,0(%r12)
	movl $0,4(%r12)
	mov %r12,%rax
	mkptrdiff32 %rax,%eax,%rdi
	test %rcx,%rcx
	jz ptn_ptout
	add %rdi,%rcx
	mkptrdiff32 %rax,%eax,%rcx,4
	ptn_ptout:
	movslq 4(%rdi),%rcx
	test %rcx,%rcx
	jnz ptn_jout
	mkptrdiff32 %rax,%eax,%rdi,4
	ptn_jout:
	ret

parse_escape:
	incq (2*8)(%rdi)
	mov (2*8)(%rdi),%rsi
	movzbq (%rsi),%rsi
	test %sil,%sil
	jz parse_exit
	jmp parse_self

parse_self:
	push %rdi
	push %rsi
	sub $2,%rsp
	movw $0,(%rsp)
	movb %sil,(%rsp)
	mov %rsp,%rdi
	mov $1,%rsi
	call write
	add $2,%rsp
	pop %rsi
	pop %rdi
	push %rsi
	movq (%rdi),%rax # rax - group
	eaptrdiff32 %rax # rax - group_alt
	mov %rax,%rdi
	movslq (%rax),%r9
	test %r9,%r9
	jz ps_alloc
	eaptrdiff32 %rax # rax - text_node
	movl (%rax),%r9d
	cmp $3,%r9d
	je ps_noalloc
	ps_alloc:
	mov $3,%rsi
	call push_tnode
	dec %r12
	mkptrdiff32 %r12,%r12d,%rax,(8+0) # text_chars.text
	inc %r12
	movl $0,(8+4)(%rax) # text_chars.len
	ps_noalloc:
	eaptrdiff32 %rax,%r9,(8+0)
	pop %rsi
	movl (8+4)(%rax),%r8d
	sub %r8,%r9
	movb %sil,(%r9)
	incl (8+4)(%rax)
	xor %rax,%rax
	ret

parse_grbegin:
parse_grend:
parse_murder:
parse_nextalt:
parse_erase:
parse_exit:
	mov $1,%rax
	ret

// rdi - regex
// rsi - callback
// rdx - cb data
entry:
	push %rbp
	mov %rsp,%rbp
	//    svregs   state   group   group_alt
	//   (r12-r14)
	sub $(3*8    + 5*8   + 3*4   + 3*4),%rsp
	mov %r12,-8(%rbp)
	mov %r13,-16(%rbp)
	mov %r14,-24(%rbp)
	mov %rsp,%r12
	mov %rdi,(-3*8-5*8 + 2*8)(%rbp) # state.regchar
	mov %rsi,(-3*8-5*8 + 3*8)(%rbp) # state.callback
	mov %rdx,(-3*8-5*8 + 4*8)(%rbp) # state.cbdata
	lea (-3*8-5*8-3*4)(%rbp),%r9
	mov %r9,(-3*8-5*8 + 0*8)(%rbp) # state.mother_gr
	mov %r9,(-3*8-5*8 + 1*8)(%rbp) # state.current_gr
	lea (-3*8-5*8-3*4)(%rbp),%r9
	lea (-3*8-5*8-3*4-3*4)(%rbp),%r8
	mkptrdiff32 %r8,%r8d,%r9 # group.alts_tail
	mkptrdiff32 %r8,%r8d,%r9,4 # group.alts_head
	movl $0,(-3*8-5*8-3*4 + 2*4)(%rbp) # group.up
	movl $0,(-3*8-5*8-3*4-3*4 + 0*4)(%rbp) # group_alt.text_tail
	movl $0,(-3*8-5*8-3*4-3*4 + 1*4)(%rbp) # group_alt.text_head
	movl $0,(-3*8-5*8-3*4-3*4 + 2*4)(%rbp) # group_alt.next
	xchg %r12,%rsp
	sub $512,%r12
	entry_parse_begin:
		mov (-3*8-5*8 + 2*8)(%rbp),%rsi
		movzbq (%rsi),%rsi # char to sil
		lea charjmpt(%rip),%r11
		movzx %sil,%r10
		shl $1,%r10
		add %r10,%r11
		movswq (%r11),%r11
		charjmpt_prej:
		lea charjmpt_prej(%rip),%r10
		add %r10,%r11
		lea (-3*8-5*8)(%rbp),%rdi # &state
		call *%r11
		test %rax,%rax
		jnz entry_parse_end
		incq (-3*8-5*8+2*8)(%rbp)
		jmp entry_parse_begin
	entry_parse_end:
	mov -8(%rbp),%r12
	mov -16(%rbp),%r13
	mov -24(%rbp),%r14
	mov %rbp,%rsp
	pop %rbp
	ret

.bss
argc:
	.zero 8
argv:
	.zero 8
