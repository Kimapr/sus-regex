#include <memory.h>
#include <stdio.h>

typedef struct {
	int alts_tail;
	int alts_head;
	int up;
} group;

typedef struct {
	int text_tail;
	int text_head;
	int next;
} group_alt;

typedef struct {
	int text;
	int len;
	int prevtmp;
} text_chars;

typedef struct {
	int type;
	int next;
	union {
		text_chars chars;
		group group;
	} data;
} text_node;

typedef struct {
	group *current_gr;
	group *mother_gr;
	char *regchar;
	void *callback;
	void* cbdata;
} parse_state;

static void *deref(int *ptrdiff) {
	return (*ptrdiff)
		? ((void*)((char*)(ptrdiff)+(*ptrdiff)))
		: NULL ;
}

static parse_state *state;
static int level=0;

static void indent(int lvl) {
	for(int i=0;i<lvl+level;i++) printf("\t");
}

static void debugger_init(parse_state* hello) {
	state = hello;
	printf("bugger summoned int=%lu\n",sizeof(int));
}

static void debugger_group(group* gr);

static void debugger_tnode(text_node* gr) {
	indent(0);printf("TNODE %llx\n",(unsigned long long)(gr));
	level++;
	indent(0);printf("TYPE\t@%llx %i\n",(unsigned long long)(&gr->type),gr->type);
	switch (gr->type) {
	case 0:
		break;
	case 1:
		indent(0);printf("MURDER\n");
		break;
	case 2:
		indent(0);printf("WIPED\n");
		break;
	case 3:
		{
			indent(0);printf("STR\t@%llx %llx\n",(unsigned long long)(&gr->data.chars.text),(unsigned long long)deref(&gr->data.chars.text));
			indent(0);printf("STRLEN\t@%llx %i\n",(unsigned long long)(&gr->data.chars.len),gr->data.chars.len);
			indent(0);printf("PREVTMP\t@%llx %llx\n",(unsigned long long)(&gr->data.chars.prevtmp),(unsigned long long)gr->data.chars.prevtmp);
			char* str = (char*)deref(&gr->data.chars.text);
			for(int i=0; i<gr->data.chars.len; i++,str--) {
				indent(1); printf("CHAR %i '%c'\n",*str,*str);
			}
		}
		break;
	case 4:
		debugger_group(&gr->data.group);
		break;
	}
	level--;
}

static void debugger_gralt(group_alt* gr) {
	indent(0);printf("GROUP_ALT %llx\n",(unsigned long long)(gr));
	level++;
	indent(0); printf("HEAD %llx\n", (unsigned long long)deref(&gr->text_head));
	for (
		text_node *gra=(text_node*)deref(&gr->text_head);
		gra!=NULL;
		gra=(text_node*)deref(&gra->next)
	) {
		debugger_tnode(gra);
	}
	indent(0); printf("TAIL %llx\n", (unsigned long long)deref(&gr->text_tail));
	for (
		text_node *gra=(text_node*)deref(&gr->text_tail);
		gra!=NULL;
		gra=(text_node*)deref(&gra->next)
	) {
		debugger_tnode(gra);
	}
	level--;
}

static void debugger_group(group* gr) {
	indent(0);printf("GROUP %llx:\n",(unsigned long long)(gr));
	level++;
	indent(0); printf("HEAD\n");
	for(
		group_alt *gra=(group_alt*)deref(&gr->alts_head);
		gra!=NULL;
		gra=(group_alt*)deref(&gra->next)
	) {
		debugger_gralt(gra);
	}
	indent(0); printf("TAIL\n");
	for(
		group_alt *gra=(group_alt*)deref(&gr->alts_tail);
		gra!=NULL;
		gra=(group_alt*)deref(&gra->next)
	) {
		debugger_gralt(gra);
	}
	level--;
}

static void debugger_print(int arg, char* meow, unsigned long long arg1, unsigned long long rsp) {
	printf("\t(rsp = %llx)\n",rsp);
	if(arg==0) {
		printf("\nBUGGING %llx %i '%c':\n",(unsigned long long)state,*state->regchar,*state->regchar);
	} else if (arg==1) {
		printf("\nBUGGED %llx %i '%c':\n",(unsigned long long)state,*state->regchar,*state->regchar);
	} else if (arg==2) {
		printf("\nMeow(%s): %llx\t%lli\n",meow,arg1,arg1);
		return;
	} else if (arg==3) {
		printf("MEOW(%s): %llx\t%lli\n",meow,arg1,arg1);
	}
	level++;
	indent(0);printf("ROOT\n");
	debugger_group(state->mother_gr);
	indent(0);printf("CURRENT\n");
	debugger_group(state->current_gr);
	level--;
	printf("\n");
}

typedef struct {
	void(*init)(parse_state*);
	void(*print)(int, char*, unsigned long long, unsigned long long);
} debugger;

static debugger debugs;

void gimme_debugger(debugger*);

static void debugger_inject() {
	debugs = (debugger){
		.init = debugger_init,
		.print = debugger_print,
	};
	gimme_debugger(&debugs);
}
