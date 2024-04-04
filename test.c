#include <amogus.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

void callback(char* str, int size, void* data) {
	char** out = (char**)data;
	*out = (char*)malloc(size);
	memcpy(str, *out, size);
}

int main() {
	char* match;
	if(!entry("meow.*|m(r(r(p..*)))",callback,&match))
		return 1;
	printf("%s",match);
}
