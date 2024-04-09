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
	int err;
//	if((err=entry("me\\|\\|ow.(nya|sin|cos)XX,[]*(||)..*|m(r(r(p..*)))",callback,&match))) {
	if((err=entry("meow()*ww|mrrp",callback,&match))) {
		printf("error: %i\n",err);
		return 1;
	}
	printf("%s",match);
}
