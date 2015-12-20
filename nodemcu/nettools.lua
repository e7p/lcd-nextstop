require("tools")

function requestTimeHTTP(server)
	if(not server) then
		server = "google.com"
	end

	local conn = net.createConnection(net.TCP, 0)
	conn:on("connection", function(conn, payload)
		conn:send("HEAD / HTTP/1.1\r\n" ..
			"Host: " .. server .. "\r\n" ..
			"Accept: */*\r\n" ..
			"User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)\r\n" ..
			"\r\n")
	end)

	conn:on("receive", function(conn, payload)
		local uptime = tmr.time()
		local serverTime = parseUnixTime(payload)
		bootTime = serverTime - uptime

		conn:close()

		--require("tools") -- TODO: is this clean code?
		--local dateTime = getDateTimeFromUnix(time())
		--print("_Received Network time: " .. string.format("%04d-%02d-%02d %02d:%02d:%02d", dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.min, dateTime.sec))
	end)

	conn:connect(80, server)
end