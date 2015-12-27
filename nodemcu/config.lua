return {

  -- Debug over serial or to a file?
  -- debug           = "file",

  -- Timezone
  timezone        = 1,

  -- SSID of network to join
  ssid            = "32C3-open-legacy",

  -- Password of network to join
  pw              = "",

  -- Prefix for mode files
  modeprefix      = "mode_",

  -- Default mode(Without prefix)
  defaultmode     = "message",

  -- Show "Day 0" etc. in the date string?
  showCongressDay = true,

  -- Width of each line in the LCD. Used to cut over-sized lines in
  -- sendLineToDisplayF
  -- TODO
  width           = 33,

  -- How often should we try to toggle modes?
  -- (This duration is not guranteed!)
  mode_toggle     = 10 *1000 -- 10s

}
