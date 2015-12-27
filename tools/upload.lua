#!/usr/bin/env lua
-- Uploads a file to the ESP via serial
-- Invocation:
-- ./upload.lua [device] [input file] [filename on esp]
-- All arguments are mandatory!

local sleep = require("socket").sleep

local readsize = 70
local pre = "file.open(%q, \"w\")\n"
local enc = "file.write([=====[%s]=====])\n"
local comp = "node.compile(%q)\nfile.remove(%q\n)"
local post = "file.flush()\nfile.close()\n"

local dev = assert(arg[1])
local src = assert(arg[2])
local to = assert(arg[3])
local delay = tonumber(arg[4]) or 0.6

local file = assert(io.open(src, "r"))
local dev = assert(io.open(dev, "w"))

io.write(("Uploading %s to %s: "):format(arg[2], arg[3]))

function w(l)
	dev:write(l)
	sleep(delay)
	io.write(".")
	io.flush()
end

w(pre:format(to))
while true do
	local cdata = file:read(readsize)
	if not cdata then
		break
	else
		w(enc:format(cdata))
	end
end
-- if arg[3]:sub(-4) == ".lua" then
-- 	w(comp:format(arg[3], arg[3]))
-- end
w(post)

io.write("\n")
