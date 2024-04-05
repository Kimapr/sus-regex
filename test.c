#include <amogus.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

void callback(char* str, int size, void* data) {
	char** out = (char**)data;
	*out = (char*)malloc(size);
	if(str!=NULL)
	memcpy(*out, str, size);
	else abort();
}

int main() {
	char* match;
	if(!entry("me\\|\\|ow.*|m(r(r(p..*)))",callback,&match))
		return 1;
	printf("%s",match);
}
