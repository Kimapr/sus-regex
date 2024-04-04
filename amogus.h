// int entry(...)
//
// Parse regex. Find matching string.
// If found:
//   call callback(
//     matched string (only valid before callback return),
//     length of the string including NUL delimiter,
//     data passed in the data argument
//   )
//   return 0
// Else:
//   return 1

typedef void (entry_callback)(char* match, int size, void* data);
int entry(char* regex, entry_callback *callback, void *data);
