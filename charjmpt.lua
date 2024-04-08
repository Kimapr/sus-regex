#!/usr/bin/env lua
print("charjmpt:")
chars = {
	['\0'] = "parse_exit",
	['('] = "parse_grbegin",
	[')'] = "parse_grend",
	['\\'] = "parse_escape",
	['|'] = "parse_nextalt",
	['['] = "parse_murder",
	['*'] = "parse_erase",
}
local def = "parse_self"
for n=0,255 do
	local c = string.char(n)
	print("\t.2byte "..(chars[c] or "parse_self").." - charjmpt_prej")
end
