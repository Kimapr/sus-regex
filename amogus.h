
typedef void(entry_callback)(char *match, int size, void *data);
int entry(const char *regex, entry_callback *callback, void *data);
