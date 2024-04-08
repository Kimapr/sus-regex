// int entry(...)
//
// Parse regex. Find matching string.
// If found:
//   call callback(
//     matched string (only valid until callback return),
//     length of the string including NUL delimiter,
//   )
//   return 0
// Else:
//   return ERR

typedef void(entry_callback)(char *match, int size, void *data);
int entry(char *regex, entry_callback *callback, void *data);
