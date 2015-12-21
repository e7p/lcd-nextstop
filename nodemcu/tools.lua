bootTime = 0
timeZone = CONFIG.timezone -- hours added to the GMT

function time()
	return bootTime + (tmr.now() / 1000000)
end

function isLeapYear(year)
	return (((year % 4) == 0 and (year % 100) ~= 0) or (year % 400) == 0)
end

function getDaysPerMonth(month, year)
	local daysPerMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	if month == 2 and isLeapYear(year) then
		return 29
	else
		return daysPerMonth[month]
	end
end

function parseUnixTime(data)
	-- assume, the date header can be found in data
	local monthAbbr = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Nov", "Dec"}
	local inDay, inMonth, inYear, inHour, inMinute, inSecond = data:match("%sDate: .-, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT%s")
	for k, v in ipairs(monthAbbr) do
		if inMonth == v then
			inMonth = k + 1
			break
		end
	end

	local numLeapDays = math.floor(inYear / 4) - math.floor(inYear / 100) + math.floor(inYear / 400) - 477 -- 477 is the number of leap days until 1970
	local daysSinceEpoch = (inYear - 1970) * 365 + numLeapDays
	for i=1,(inMonth-1) do
		daysSinceEpoch = daysSinceEpoch + getDaysPerMonth(i, inYear)
	end
	daysSinceEpoch = daysSinceEpoch + inDay

	return math.floor((((daysSinceEpoch - 1) * 24 + inHour) * 60 + inMinute) * 60 + inSecond)
end

function getDateTimeFromUnix(time)
	time = time + 60 * 60 * timeZone

	local day = math.floor(time / 86400)
	local secondsOfDay = time % 86400

	local year = 1970
	local daysOfYear
  	while(true) do
  		if(isLeapYear(year)) then
  			daysOfYear = 366
  		else
  			daysOfYear = 365
  		end
  		if(day < daysOfYear) then
  			break
  		end
  		day = day - daysOfYear
  		year = year + 1
  	end

  	local month = 1
  	while(day >= getDaysPerMonth(month, year)) do
  		day = day - getDaysPerMonth(month, year)
  		month = month + 1
  	end

  	day = day + 1

  	local second = secondsOfDay % 60
  	secondsOfDay = math.floor(secondsOfDay / 60)
  	local minute = secondsOfDay % 60
  	secondsOfDay = math.floor(secondsOfDay / 60)
  	local hour = secondsOfDay

  	return {year = year, month = month, day = day, hour = hour, min = minute, sec = second}
end
