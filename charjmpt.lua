#!/usr/bin/env lua
print("charjmpt:")
chars = {
	['\0'] = "parse_exit",
}
local def = "parse_self"
for n=0,255 do
	local c = string.char(n)
	print("\t.4byte "..(chars[c] or "parse_self").." - charjmpt_prej")
end
