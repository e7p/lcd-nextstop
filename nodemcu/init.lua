CONFIG = require("config")
require("nettools")

local wifiUp = false



-- Debug printf
if CONFIG.debug == "file" or CONFIG.debug == "serial" then
  function dprint(str, ...)
    if CONFIG.debug == "file" then
      -- TODO: Buffering? The flash has limited write cycles! Also, increase speed!
      file.open("debug.txt", "a+")
      file.writeline(str:format(...))
      file.close()
    elseif CONFIG.debug == "serial" then
      print("Debug: ", str:format(...))
    end
  end
else
  -- Save some RAM & CPU time by not having a real debug function if debug is disabled.
  function dprint() end
end



-- Print data to display(Or, ATM, diffrent uC). For mapping see README.md
function sendToDisplay(...)
	uart.write(0, ...)
end



-- Print formated string to display
function sendLineToDisplayF(str, ...)
	uart.write(0, (str:format(...)):sub(1, CONFIG.width) )
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
          if not modes[currentMode]:deactivate() then
            -- Function returned no error, we're ok to switch modes!
            currentMode = nextMode
            nextMode:activate()
          else
            -- Not yet ready...
            -- dprint("Module not ready to switch yet!")
          end
        end
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
    IDLE       = wifi.wifi_event_IDLE,
    CONNECTING = wifi.wifi_event_CONNECTING,
    WRONGPWD   = wifi.wifi_event_WRONGPW,
    APNOTFOUND = wifi.wifi_event_APNOTFOUN,
    FAIL       = wifi.wifi_event_FAIL,
    GOTIP      = wifi.wifi_event_GOTIP
  }

  -- Register a callback function for each
  for state, func in pairs(states) do
    local statecode = wifi["STA_" .. state]
    wifi.sta.eventMonReg(statecode, "unreg")
    wifi.sta.eventMonReg(statecode, func)
  end
end





--[[ Wifi callbacks ]]--
 -- see setupWifi() on how they are called!

function wifi_event_IDLE(prev)
  dprint("Wifi is idle...")
  wifiup = false
end

function wifi_event_CONNECTING(prev)
  dprint("Connecting...")
  wifiup = false
end

function wifi_event_WRONGPW(prev)
  dprint("Wrong password. Check config!")
  wifiup = false
end

function wifi_event_APNOTFOUN(prev)
  dprint("Can't find AP. Check range and config!")
  wifiup = false
end

function wifi_event_FAIL(prev)
  dprint("Wifi error!")
  wifiup = false
end

function wifi_event_GOTIP(prev)
  dprint("Got IP! (Now connected!)")
  requestTimeHTTP()
  wifiup = true
end





function main()
  setupWifi()
  toggleMode()
	tmr.alarm(0, CONFIG.mode_toggle, 1, toggleMode)
	uart.on("data", "\r", exit, 0)
end



function exit()
	tmr.stop(0)
	uart.on("data") -- reset uart interrupt
end



main()
