local mode = {

  -- Name(used access to mode)
  name = "trains",

  -- Description(for help command)
  description = "Shows train departure at Hamburg Dammtor",

  -- Does this mode need wifi?
  needsWifi = true

}



function mode.activate()
	-- TODO implement Trains
	sendToDisplay("\1\16== Hamburg Dammtor ==\n")
end



return mode
