#include <amogus.h>
#include "sus.h"
//#include "regexofhell.h"
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
	debugger_inject();
	char* match;
	int err;
//	if((err=entry("me\\|\\|ow.(nya|sin|cos)XX,[](||)..|m(r(r(p..)))",callback,&match))) {
//	if((err=entry("meow()*[]ww|mrrp",callback,&match))) {
//	if((err=entry(regexofhell,callback,&match))) {
	if((err=entry("",callback,&match))) {
//	if((err=entry("me*ow[]*|mrrp",callback,&match))) {
		printf("error: %i\n",err);
		return 1;
	}
	printf("%s",match);
}
