#!/usr/bin/env lua
-- Prentends to be a ESP running Nodemcu, and reading an input file.


local empty = function() end

local ret = ""

file = {
	open = empty,
	close = empty,
	flush = empty,
	write = function(s)
		ret = ret .. s
	end
}

dofile(arg[1] or "test.txt")

io.write(ret)
