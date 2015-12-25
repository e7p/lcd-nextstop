#!/usr/bin/env lua
--[[
This file strips a shedule(Obtained from
https://events.ccc.de/congress/2015/Fahrplan/schedule.json for example),
and first splits it into days, then strips the results, to save memory on the
esp8266. It also converts dates to unix time.

It's designed to be run on a host PC with lua-cjson installed!
(sudo apt-get install lua-cjson)

First and only argument is the path to the schedule.json
(Defaults to schedule.json
--]]
function printf(str, ...)
	print(str:format(...))
end

function pack(...)
	return {...}
end

local json = require("cjson")
local infile = io.open(arg[1] or "schedule.json")
if not infile then
	print("Can't open input file!")
	os.exit(1)
end
local obj = json.decode(infile:read("*a"))
infile:close()

printf("Schedule version: %q", obj.schedule.version)

for _, day in pairs(obj.schedule.conference.days) do
	local cday = {
		index = day.index,
		events = {}
	}
	for _, room in pairs(day.rooms) do
		for _, event in pairs(room) do
--			printf("Day %d, room %s: %s", day.index, event.room, event.title)
			local day, hour, min = event.date:match("2015.12.(%d+)T(%d+):(%d+)")
			local date = {
				year = 2015,
				month = 12,
				day = tonumber(day),
				hour = tonumber(hour),
				min = tonumber(min)
			}
			local unixt = os.time(date)
			local d_hours, d_mins = event.duration:match("(%d+):(%d+)")
			local duration = (tonumber(d_hours) * 60) + tonumber(d_mins)
			table.insert(cday.events, {
				start = unixt,
				stop = unixt + duration,
				room = event.room,
				title = event.title
			})
		end
	end

	local outfile = io.open("day_" .. day.index .. ".json", "w")
	outfile:write(json.encode(cday))
	outfile:close()

end

