local mode = {

  -- Display name and Description (For help command etc.)
  name = "timedate",
  description = "Shows time, date and congress day",

  -- Does this mode need wifi?
  needsWifi = true

}



function modes.TIMEDATE.canActivate()
	return (bootTime ~= 0)
end



function modes.TIMEDATE.activate()
	tmr.alarm(2, 1000, 1, modes.TIMEDATE.display)
end



function modes.TIMEDATE.display()
	local dateTime = getDateTimeFromUnix(time())

  local dateStr = string.format("%04d-%02d-%02d", dateTime.year, dateTime.month, dateTime.day)
  local timeStr = string.format("%02d:%02d:%02d", dateTime.hour, dateTime.min, dateTime.sec)
  local congressDayStr = ""
  if(CONFIG.showCongressDay and dateTime.month == 12) then
		congressDayStr = string.format(" (day %d)", dateTime.day - 26)
  end

	sendToDisplay("\1\n\16", dateStr, congressDayStr, "\n\16", timeStr, "\n")
end



function modes.TIMEDATE.deactivate()
	tmr.stop(2)
end



return mode
