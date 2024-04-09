.globl _start
.type _start, @function

.set bitesize, 0x1000

_start:
	pop %rax
	mov %rax,argc(%rip)
	mov %rax,%rdi
	pop %rax
	mov %rax,argv(%rip)
	cmp $1,%rdi
	jle _start_endif
	mov $1,%rdi
	call usage
	jmp _exit
	_start_endif:

	mov $12,%rax # brk
	mov $0,%rdi
	syscall

	mov %rax,%r13
	xor %r12,%r12
	rloop:
	mov %r13,%rdi
	add %r12,%rdi
	push %rdi
	add $bitesize,%rdi
	mov $12,%rax
	syscall
	pop %rdi
	cmp %rdi,%rax
	jne skipdie
	movq $0,0
	skipdie:
	mov $0,%rax
	mov $0,%rdi
	mov %r13,%rsi
	add %r12,%rsi
	mov $bitesize,%rdx
	syscall
	add %rax,%r12
	test %rax,%rax
	jnz rloop
	inc %r12

	pop %rax
	mov %r13,%rdi
	add %r12,%rdi
	push %rdi
	mov $12,%rax
	syscall
	pop %rdi
	dec %rdi
	movb $0,(%rdi)
	mov %r13,%rdi
	lea write(%rip),%rsi
	call Lentry

	mov %rax,%rdi
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
	xor %ecx,%ecx
	dec %rcx
	mov %rdi,%rsi
	xor %rax,%rax
	repne scasb
	sub %rsi,%rdi
	mov %rdi,%rax
	dec %rax
	ret

sbrk:


// rdi - buf
// rsi - len
write:
	push %rdx
	push %rdi
	push %rsi
	pop %rdx
	pop %rsi
	mov $1,%rax
	mov $1,%rdi
	push %rcx
	push %r11
	syscall
	pop %r11
	pop %rcx
	pop %rdx
	ret

help0:
	.ascii "Usage: "
	.set help0l, .-help0
	.ascii "./amogus"
help1:
	.ascii "\nRead from standard input, write to standard output."
	.ascii "\nFind a string matched by a regular expression.\n"
	.ascii "\nAsssumes unlimited call stack space.\n"
	.set help1l, .-help1

// rdi - exit code
_exit:
	mov $0x3c,%rax
	syscall
	ret

.macro print str=""
	jmp printps\@
	print\@:
.altmacro
	.ascii "\str"
.noaltmacro
	.set print\@l , . - print\@
	printps\@:
	push %rdi
	push %rsi
	push %rdx
	push %rax
	lea "print\@" (%rip),%rdi
	mov $"print\@l" , %rsi
	call write
	pop %rax
	pop %rdx
	pop %rsi
	pop %rdi
.endm

.macro eaptrdiff32 ptr:req, out:req, off=0, tmp=%r11
	eaptrdiff32.\@:
	.if (\ptr == \tmp) || (\out == \tmp)
	.error "broken tmp"
	.endif
	.if \ptr != \out
	push \ptr
	.endif
	.if \off
	add $\off,\ptr
	.endif
	push \tmp
	mov \ptr,\tmp
	movslq (\tmp),\tmp
	test \tmp,\tmp
	jnz eaptrdiffnz.\@
	xor \ptr,\ptr
	eaptrdiffnz.\@:
	add \tmp,\ptr
	pop \tmp
	.if \ptr != \out
	mov \ptr,\out
	pop \ptr
	.endif
	eaptrdiff32o.\@:
.endm

.macro mkptrdiff32 to:req, to_low=%r11d, ptr:req, off=0
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

.globl gimme_debugger
gimme_debugger:
	mov %rdi,debugit(%rip)
	ret

.macro debugger_print arg=0, str="", pr_reg=%rsi
	push %rax
	push %rdx
	mov \pr_reg,%rdx
	mov debugit(%rip),%rax
	test %rax,%rax
	jz dbgpei\@
	push %rdi
	push %rsi
	push %r8
	push %r9
	push %r10
	push %r11
	push %rcx
	mov %rsp,%rcx
	mov $\arg,%rdi
	jmp printps\@
	print\@:
.altmacro
	.ascii "\str"
	.byte 0
.noaltmacro
	printps\@:
	lea print\@(%rip),%rsi
	mov 8(%rax),%rax
	call *%rax
	pop %rcx
	pop %r11
	pop %r10
	pop %r9
	pop %r8
	pop %rsi
	pop %rdi
	dbgpei\@:
	pop %rdx
	pop %rax
.endm

.macro debugger_init
	push %rax
	mov debugit(%rip),%rax
	test %rax,%rax
	jz dbgpei\@
	push %rdi
	push %rsi
	push %rdx
	push %rcx
	push %r8
	push %r9
	push %r10
	push %r11
	lea (-3*8-5*8)(%rbp),%rdi
	mov (%rax),%rax
	call *%rax
	pop %r11
	pop %r10
	pop %r9
	pop %r8
	pop %rcx
	pop %rdx
	pop %rsi
	pop %rdi
	dbgpei\@:
	pop %rax
.endm

// rdi - regex
// rsi - callback
// rdx - cb data
Lentry:
entry:
	push %rbp
	mov %rsp,%rbp
	//    svregs   state   group   group_alt
	//   (r12-r14)
	sub $(3*8    + 5*8   + 3*4   + 3*4),%rsp
	debugger_init
	mov %r12,-8(%rbp)
	mov %r13,-16(%rbp)
	mov %r14,-24(%rbp)
	mov %rsp,%r12
	sub $65536,%r12
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
		epl_call:
		call *%r11
		cmp $1,%rax
		jg entry_parse_fail
		test %rax,%rax
		jnz entry_parse_end
		incq (-3*8-5*8+2*8)(%rbp)
		jmp entry_parse_begin
	entry_parse_end:
	xchg %r12,%rsp
	#mov $0,%rax
	lea (-3*8-5*8)(%rbp),%rdi # &state
	mov 8(%rdi),%rsi # mother_gr
	eaptrdiff32 %rsi,%rsi,4 # alts_head
	xor %rdx,%rdx # len
	xor %rcx,%rcx # tnode
	mov %rsp,%r12
	call traverse_ast
	mov $1,%rax
	entry_untraverse:
	debugger_print 3, "ENDOF ATNR", %rsp
	entry_parse_fail:
	mov %r12,%rsp
	mov -8(%rbp),%r12
	mov -16(%rbp),%r13
	mov -24(%rbp),%r14
	mov %rbp,%rsp
	pop %rbp
	ret

// rdi - &state
// rsi - option<&group_alt>
// rdx - len
// rcx - option<&tnode>
traverse_ast:
	test %rsi,%rsi
	jz tast_bye
	push %rsi
	push %rdx
	push %rcx
	eaptrdiff32 %rsi,%rsi,4
	call traverse_galt
	pop %rcx
	pop %rdx
	pop %rsi
	eaptrdiff32 %rsi,%rsi,(2*4)
	jmp traverse_ast
	tast_bye:
	ret

// rdi - &state
// rsi - option<&tnode>
// rdx - len
// rcx - option<&tnode>
traverse_galt:
	test %rsi,%rsi
	jnz tgand
	tgfin:
	test %rcx,%rcx
	jz tgad
	dec %rsp
	movb $0,(%rsp)
	tgalb:
	movl (2*4+1*4)(%rcx),%r8d
	eaptrdiff32 %rcx,%r9,(2*4)
	sub %r8,%r9
	inc %r9
	tgscpb:
	test %r8,%r8
	jz tgscpe
	dec %rsp
	mover:
	#debugger_print 2, "galtchar" %r8
	movb (%r9),%r10b
	movb %r10b,(%rsp)
	inc %r9
	dec %r8
	jmp tgscpb
	tgscpe:
	eaptrdiff32 %rcx,%rcx,(2*4+2*4)
	test %rcx,%rcx
	jnz tgalb
	tgad:
	mov %rdi,%rcx
	mov %rsp,%rdi
	mov %rdx,%rsi
	mov (4*8)(%rcx),%rdx
	mov (3*8)(%rcx),%rcx
	and $-16,%rsp
	call *%rcx
	xor %rax,%rax
	jmp entry_untraverse
	tgand:
	movl (%rsi),%r9d
	cmp $1,%r9
	je tgt_murder
	cmp $2,%r9
	je tgt_bye
	cmp $3,%r9
	je tgt_chars
	cmp $4,%r9
	je tgt_group
	movb $0,0
	tgt_murder:
	ret
	tgt_wiped:
	jmp tgt_bye
	tgt_chars:
	movl (2*4+1*4)(%rsi),%r8d
	add %r8,%rdx
	movl $0,(2*4+2*4)(%rsi)
	test %rcx,%rcx
	jz nosetptr
	mkptrdiff32 %rcx,%ecx,%rsi,(2*4+2*4)
	nosetptr:
	mov %rsi,%rcx
	jmp tgt_bye
	tgt_group:
	push %rsi
	eaptrdiff32 %rsi,%rsi,(2*4+1*4)
	call traverse_ast
	pop %rsi
	tgt_bye:
	eaptrdiff32 %rsi,%rsi,4
	jmp traverse_galt

// rdi - &state
// rsi - char
// rcx, r8, r9, r10, r11 - scratch
// r12 - real stack (rsp - fake stack)
// -> rax - status
//parse_...:

parse_escape:
	incq (2*8)(%rdi)
	mov (2*8)(%rdi),%rsi
	movzbq (%rsi),%rsi
	test %sil,%sil
	jz parse_exit
	jmp parse_self

parse_self:
	/*
	push %rdi # DBG{
	push %rsi
	mov %rsp,%rdi
	mov $1,%rsi
	call write
	pop %rsi
	pop %rdi # DBG}
	//*/

	push %rsi
	movq (%rdi),%rax # rax - group
	eaptrdiff32 %rax,%rax # rax - group_alt
	mov %rax,%rdi
	movslq (%rax),%r9
	test %r9,%r9
	jz ps_alloc
	eaptrdiff32 %rax,%rax # rax - text_node
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
	movsil:
	dec %r12
	sub %r8,%r9
	movb %sil,(%r9)
	incl (8+4)(%rax)
	xor %rax,%rax
	ret

.include "target/charjmpt.s"

parse_grbegin:
	push %rdi
	movq (%rdi),%rax # rax - group
	push %rax
	eaptrdiff32 %rax,%rdi # rdi - group_alt
	mov $4,%rsi
	call push_tnode # rax - ng_text_node
	pop %rsi # rsi - group
	pop %rdi # rdi - state
	lea (2*4)(%rax),%rax # rax - newgroup
	mkptrdiff32 %rsi,%esi,%rax,(2*4)
	mov %rax,(%rdi)
	sub $(3*4),%r12
	mkptrdiff32 %r12,%r12d,%rax
	mkptrdiff32 %r12,%r12d,%rax,4
	movl $0,(0*4)(%r12)
	movl $0,(1*4)(%r12)
	movl $0,(2*4)(%r12)
	xor %rax,%rax
	ret

parse_grend:
	movq (%rdi),%rax # rax - group
	movl (2*4)(%rax),%esi # rsi - upgroup off
	pgrt:
	test %rsi,%rsi
	jnz pgre_nodie
	mov $2,%rax
	ret
	pgre_nodie:
	eaptrdiff32 %rax,%rax,(2*4) # rax - upgroup
	mov %rax,(%rdi)
	xor %rax,%rax
	ret

parse_nextalt:
	mov (%rdi),%rdi # group
	eaptrdiff32 %rdi,%rsi,(0*4) # group_alt orig
	sub $(3*4),%r12
	movl $0,(0*4)(%r12)
	movl $0,(1*4)(%r12)
	movl $0,(2*4)(%r12)
	mkptrdiff32 %r12,%r12d,%rsi,(2*4)
	mkptrdiff32 %r12,%r12d,%rdi
	ret

parse_murder:
	incq (2*8)(%rdi)
	mov (2*8)(%rdi),%rsi
	movzbq (%rsi),%rsi
	cmp $'],%sil
	je pm_succ
	mov $3,%rax
	ret
	pm_succ:
	mov (%rdi),%rdi # group
	eaptrdiff32 %rdi,%rdi # group_alt
	mov $1,%rsi
	call push_tnode
	xor %rax,%rax
	ret

parse_erase:
	mov (%rdi),%rsi # group
	eaptrdiff32 %rsi,%rsi # group_alt
	eaptrdiff32 %rsi,%rcx
	test %rcx,%rcx
	je pers_push
	eaptrdiff32 %rsi,%rcx # text_node
	movl (%rcx),%r8d # type
	cmp $3,%r8d
	je pers_text
	jmp pers_set
	pers_text:
	movl (2*4)(%rcx),%r8d
	test %r8d,%r8d
	jz pers_set
	decl (2*4+4)(%rcx)
	inc %r12
	xor %rax,%rax
	ret
	pers_set:
	movl $2,(%rcx)
	#mov %rcx,%r12
	xor %rax,%rax
	ret
	pers_push:
	mov %rsi,%rdi
	mov $2,%rsi
	call push_tnode
	xor %rax,%rax
	ret

parse_exit:
	mov $1,%rax
	ret

// rdi - &tnode to
// rsi - &tnode ptr
append_tnode_recurse:
	mkptrdiff32 %rdi,%edi,%rsi,4
	movl (%rsi),%r8d
	cmp $4,%r8d
	jne atnr_exit
	lea (2*4)(%rsi),%rsi # rsi - group
	eaptrdiff32 %rsi,%r10,4 # r10 - group_alt
	atnr_nn:
	eaptrdiff32 %r10,%r11,0,%r9 # r11 - tnode
	push %r10
	test %r11,%r11
	jz atnr_rej
	mov %r11,%rsi
	call append_tnode_recurse
	jmp atrnr_norej
	atnr_rej:
	mkptrdiff32 %rdi,%edi,%r10
	mkptrdiff32 %rdi,%edi,%r10,4
	atrnr_norej:
	pop %r10
	eaptrdiff32 %r10,%r10,8
	test %r10,%r10
	jnz atnr_nn
	atnr_exit:
	ret

// rdi - &group_alt
// rsi - type
// -> rax - text_node ptr
push_tnode:
	eaptrdiff32 %rdi,%rcx
	sub $(5*4),%r12
	and $-4,%r12
	movl %esi,0(%r12)
	movl $0,4(%r12)
	mov %r12,%rax
	mkptrdiff32 %rax,%eax,%rdi
	test %rcx,%rcx
	jz ptn_ptout
	push %rax
	push %rdi
	mov %rax,%rdi
	mov %rcx,%rsi
	xchg %r12,%rsp
	call append_tnode_recurse
	xchg %r12,%rsp
	pop %rdi
	pop %rax
	ptn_ptout:
	movslq 4(%rdi),%rcx
	test %rcx,%rcx
	jnz ptn_jout
	mkptrdiff32 %rax,%eax,%rdi,4
	ptn_jout:
	ret

.globl entry
.type entry, @function

.bss
argc:
	.zero 8
argv:
	.zero 8
debugit:
	.zero 8
