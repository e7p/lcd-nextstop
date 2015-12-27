local mode = {

  -- Display name and Description (For help command etc.)
  name = "fahrplan",
  description = "Shows congress fahrplan",

  -- Does this mode need wifi?
  needsWifi = true,

  rooms = {
    "Hall 6",
    "Hall G",
    "Hall 2",
    "Hall 1"
  },

  croom = 1

}



function mode.activate(self)
  if not self.data then
    local json = require("cjson")
    local congressDay = getDateTimeFromUnix(time()).day - 26
    file.open("day_" .. congressDay .. ".json")
    self.data = json.decode(file.read())
    infile.close()
  end
  self:displayCurrent()
end

function mode.deactivate(self)
  -- Abuse this function to switch between rooms every 10 or so seconds.
  if croom < #rooms then
    self.croom = self.croom + 1
    self:displayCurrent()
    return true -- Don't switch mode just yet!
  else
    -- Unload data to save RAM for other modules!
    self.data = nil
    return false
  end
end

function mode.displayCurrent()
  local cpresentation
  local ctime = time()
  for room_name,room in pairs(self.data.rooms[self.rooms[self.croom]]) do
    for _,presentation in pairs(room) do
      if presentation.stop > ctime then
        -- !!!TODO!!! --
        -- Rethink this(It's 4:30, no clue if this makes sense.)
        if cpresentation.start < presentation.start then
          cpresentation = presentation
        end
        -- /todo --
      end
    end
  end

  sendToDisplayF("\1\16== Current talks (%s) ==\n", self.rooms[self.croom])
  local date = getDateTimeFromUnix(cpresentation.start)
  sendToDisplayF("Start: %d:%d\n", date.hour, date.min)
  date = getDateTimeFromUnix(cpresentation.stop)
  sendToDisplayF("Stop:  %d:%d\n", date.hour, date.min)
  sendToDisplayF("Title: %s\n", cpresentation.title)
end

return mode
