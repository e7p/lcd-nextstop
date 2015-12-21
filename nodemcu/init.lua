CONFIG = require("config")
require("nettools")

local wifiUp = false



-- Debug printf
function dprint(str, ...)
  if CONFIG.debug then
    print("Debug: ", str:format(...))
  end
end



-- Print data to display(Or ATM diffrent uC). For mapping see README.md
function sendToDisplay(...)
	uart.write(0, ...)
end



-- Load aviable modes
dprint("Loading modules...")
local modes = {} -- Modes as
local currentMode -- Number of current mode
for file, size in pairs(file.list()) do
  if files:gsub(1, #CONFIG.modeprefix) == CONFIG.modeprefix then
    -- The filename starts with the modeprefix, try to load it as a mode!
    local ok, mode = pcall(require, file:gsub(".lua")) -- Require doesn't work with a file extension!
    if ok then
      dprint("Loaded module: %s (File: %s, Size: %d)", mode.name, file, size)
      modes[#modes + 1] = mode
      if modes.name == CONFIG.defaultmode then
        currentMode = #modes
      end
    else
      dprint("Can't load module: %s, (Error: %s)", file, error)
    end
  end
end
dprint("Loaded %d modules!", #modules)
if not currentMode then
  dprint("Couldn't find default mode! (Check config, using first mode for now)")
  currentMode = 1
end



-- Toggles to a diffrent mode if possible, does nothing if not
function toggleMode()
  for i=1, #modes do
    local nextMode = modes[(currentMode + i) % #modes]
    if (nextMode.canActivate and nextMode.canActivate()) or (not nextMode.canActivate) then
      -- We either have canActivate defined and it returned true, or canActivate is not set.
      run = false
      if nextMode.needsWifi and apConnected then
        run = true
      elseif not nextMode.needsWifi then
        run = true
      end
      if run then
        dprint("Changing mode to %s", nextMode.name)
        if modes[currentMode].deactivate then
          modes[currentMode]:deactivate()
        end
        nextMode:activate()
      end
    end
  end
  dprint("No mode capable of running found! Not toggling mode!")
end



-- Connects to wifi
function setupWifi()

  if wifi.getmode() ~= 1 then
    -- We're not in Client mode?
    wifi.setmode(wifi.STATION)
  end

  local conf = wifi.sta.getconfig()
  if (conf.ssid ~= CONFIG.SSID) or (conf.pw ~= CONFIG.pw) then
    -- Wifi settings are wrong!
    wifi.sta.config(CONFIG.ssid, CONFIG.pw, 1)
    -- Should be done automaticly: wifi.sta.connect()
  end

  -- Enable automatic connecting and reconnecting
  wifi.sta.autoconnect(1)

  -- Start event monitor, so we know when the wifi is up/down
  wifi.sta.eventMonStart()

  -- States the wifi can change to
  local states = {
    IDLE       = wifi.STA_IDLE,
    CONNECTING = wifi.STA_CONNECTING,
    WRONGPWD   = wifi.STA_WRONGPWD,
    APNOTFOUND = wifi.STA_APNOTFOUND,
    FAIL       = wifi.STA_FAIL,
    GOTIP      = wifi.STA_GOTIP
  }

  -- Register a callback function for each
  for name, state in pairs(states) do
    wifi.sta.eventMonReg(state, "unreg")
    wifi.sta.eventMonReg(state, function(prev)
      -- You can save some RAM here by not using 5x2 upvalues, but loose debugging and convenience
      dprint("Wifi switched from state %s to %s(%s)", prev, state, name)
      if _G["wifi_event_" .. name] then
        _G["wifi_event_" .. name](prev)
      end
    end)
  end
end





--[[ Wifi callbacks ]]--
 -- see setupWifi() on how they are called!

function wifi_event_IDLE()
  wifiup = false
end

function wifi_event_CONNECTING()
  wifiup = false
end

function wifi_event_WRONGPW()
  dprint("Wrong password. Check config!")
  wifiup = false
end

function wifi_event_APNOTFOUN()
  dprint("Can't find AP. Check range and config!")
  wifiup = false
end

function wifi_event_FAIL()
  wifiup = false
end

function wifi_event_GOTIP()
  dprint("Got IP!")
  requestTimeHTTP()
  wifiup = true
end





function main()
  modes[currentMode]:activate()
	tmr.alarm(0, CONFIG.mode_toggle, 1, toggleMode)
	uart.on("data", "\r", exit, 0)
end



function exit()
	tmr.stop(0)
	uart.on("data") -- reset uart interrupt
end



main()
