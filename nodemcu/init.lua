-- general settings are below
-- AP login data
local AP_SSID     = "Freifunk-Wuppertal"
local AP_PW       = ""

-- Text output:
--[[ our byte subset (of generally supported UTF-8) looks like:
	Hex	Lua	Description
	0x00	\0	end of string
	0x01	\1	clear the whole display and set position to start
	0x07	\a	-
	0x08	\b	backspace the last character
	0x09	\t	horizontal tab (tab width may be set to fit all data in
			tabular form on the display)
	0x0A	\n	new line (following an automatic carriage return)
	0x0B	\v	vertical tab (go to the last line directly)
	0x0C	\f	-
	0x0D	\r	carriage return (go to the start of line)
	0x10	\16	center the current line
	0x20 - 0xFF	common ASCII characters / UTF-8 values
]]

-- Usage of timers:
--[[
	0	continuously check if wifi is established
	1	toggle the mode with this alarm
	2	- may be freely used by the currently active mode -
]]

-- local and global variables
local apConnected = false
local apConfigured = false
modes = {
	MESSAGE = {
		needsWifi = false,
		text = "\1\n\16Powered by\n\16/dev/tal\n"
	}, TIMEDATE = {
		needsWifi = true
	}, FAHRPLAN = {
		needsWifi = true
	}, TRAINS = {
		needsWifi = true
	}
}
local currentMode = modes.MESSAGE;


-- TODO: put modes in submodules somehow...

require("nettools")

showCongressDay = true

function modes.TIMEDATE.canActivate()
	return (bootTime ~= 0)
end

function modes.TIMEDATE.activate()
	tmr.alarm(2, 1000, 1, modes.TIMEDATE.display)
end

function modes.TIMEDATE.display()
	local dateTime = getDateTimeFromUnix(time())

  	local dateStr = string.format("%04d-%02d-%02d", dateTime.year, dateTime.month, dateTime.day)
  	local congressDayStr = ""
  	if(showCongressDay and dateTime.month == 12) then
	  	congressDayStr = string.format(" (day %d)", dateTime.day - 26)
  	end
  	local timeStr = string.format("%02d:%02d:%02d", dateTime.hour, dateTime.min, dateTime.sec)
	sendToDisplay("\1\n\16" .. dateStr .. congressDayStr .. "\n\16" .. timeStr .. "\n")
end

function modes.TIMEDATE.deactivate()
	tmr.stop(2)
end


function changeMode(mode)
	if(currentMode.deactivate ~= nil) then
		currentMode.deactivate()
	end
	currentMode = mode;
	currentMode.activate();
end

function sendToDisplay(data)
	uart.write(0, data)
end

function modes.MESSAGE.activate()
	sendToDisplay(modes.MESSAGE.text) -- TODO make this work like "self.text"
end

function modes.FAHRPLAN.activate()
	-- TODO implement Fahrplan
	sendToDisplay("\1\16== Current talks (Saal 1) ==\n")
end

function modes.TRAINS.activate()
	-- TODO implement Trains
	sendToDisplay("\1\16== Hamburg Dammtor ==\n")
end

function toggleMode(startWithNext)
	useNext = startWithNext
	--print("_Toggle Mode now...")
	for k, v in pairs(modes) do
		if(useNext and (apConnected or not v.needsWifi) and (v.canActivate == nil or v.canActivate())) then
			-- use the current value as next mode
			--print("_New Mode: " .. k)
			changeMode(v)
			--print("_Mode changed!")
			return
		elseif(not useNext and v == currentMode) then
			--print("_Old Mode: " .. k)
			useNext = true
		end
	end
	if (useNext and not startWithNext) then
		toggleMode(true)
	else
		--print("_No possible mode found, oops")
	end
end

local lastTimeRequest = 0

function checkWifi()
	local ip = wifi.sta.getip()
	if(ip == nil) then
		apConnected = false
		if(not apConfigured) then
			--print("_Configure WIFI...")
			wifi.setmode(wifi.STATION)
			wifi.sta.config(AP_SSID, AP_PW)
			apConfigured = true
		end
		if(currentMode.needsWifi) then
			tmr.alarm(1, 10000, 1, toggleMode) -- reset timer 1
			toggleMode()
		end
	elseif(not apConnected) then
		apConnected = true
		--print("_Connected, IP: " .. ip)

		lastTimeRequest = tmr.now()
		requestTimeHTTP()
	end
	if(lastTimeRequest > tmr.now()) then
		-- this jump happens around all 35 minutes, because of the uint31
		lastTimeRequest = tmr.now()
		if(apConnected) then
			requestTimeHTTP()
		end
	end	
end

function main()
	tmr.alarm(0, 2500, 1, checkWifi)

	-- activate first mode and toggle modes every 10 seconds
	currentMode.activate()
	tmr.alarm(1, 10000, 1, toggleMode)
	uart.on("data", "\r", exit, 0)
end

main()

function exit()
	tmr.stop(0)
	tmr.stop(1)
	uart.on("data") -- reset uart interrupt
end