#include <amogus.h>
#include <stdio.h>

int main() {
	char* match;
	if(!entry("meow.*|m(r(r(p..*)))",&match))
		return 1;
	printf("%s",match);
}
