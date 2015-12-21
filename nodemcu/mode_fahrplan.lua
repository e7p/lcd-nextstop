local mode = {

  -- Display name and Description (For help command etc.)
  name = "fahrplan",
  description = "Shows congress fahrplan",

  -- Does this mode need wifi?
  needsWifi = true

}



function mode.activate()
	-- TODO implement Fahrplan
	sendToDisplay("\1\16== Current talks (Saal 1) ==\n")
end



return mode
