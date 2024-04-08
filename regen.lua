#!/usr/bin/env lua
local chs={}
local function dchar(n)
	local ch=string.char(n)
	local cho=ch
	if ch:match("[^%w ]") then
		ch="\\"..ch
	end
	chs[#chs+1]=function()
		return ch,ch,cho
	end
end
local recurse=0;
local function dren()
	return asterisked==0 and badl==0
end
local out=""
for n=32,126 do
	dchar(n)
end
chs[#chs+1]=function() return "([]*)","","" end
local function charf()
	local chl=chs
	return function()
		local c,b,o=chl[math.random(1,#chl)]()
		return c,b,o
	end
end
local str
local char=charf()
function str(n,bad)
	local t={}
	local ot={}
	local ob={}
	for x=1,n do
		t[#t+1],ob[#ob+1],ot[#ot+1]=char()
	end
	if bad then
		if n>0 then
			t[math.random(1,#t)]=math.random()>0.5 and t[n].."[]" or "[]"..t[n]
		else
			t[#t+1]='[]'
		end
	end
	return table.concat(t),bad and '' or table.concat(ob),bad and '' or table.concat(ot)
end
str=(function(str) return function(min,man,c)
	local t={}
	local goods={}
	for n=1,1 do
		local nn
		repeat
			nn=math.random(1,c)
		until not goods[nn]
		goods[nn]=true
	end
	local ot
	local ob
	for n=1,c do
		local o
		local oc
		t[n],oc,o=str(math.random(min,man),not goods[n])
		if goods[n] then
			ot=o
			ob=oc
		end
	end
	return table.concat(t,'|'),ob,ot
end end)(str);

local mrecurse=0
char=(function(char) return function()
	local c,o
	local b
	local ast=math.random()<0.2
	if math.random()<0.05*(1-math.atan(recurse*(1.5))/math.atan(math.huge)) then
		local s
		recurse=recurse+1
		if recurse>mrecurse then
			mrecurse=math.max(mrecurse,recurse)
			io.stderr:write(mrecurse,' rec\n')
		end
		s,b,o=str(0,16,math.random(1,64))
		recurse=recurse-1
		c='('..s..')'
	else
		c,b,o=char()
	end
	if math.random()<0.2 then
		c=c.."*"
		b=c
		o=''
	end
	return c,b,o
end end)(char)

local s,b,o=str(0,16,256)
print(s)
io.stderr:write(mrecurse,' rec\n')
io.stderr:write(b,'\n')
io.stderr:write(o,'\n')
