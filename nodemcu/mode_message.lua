local mode = {

  -- Display name and Description (For help command etc.)
  name = "message",
  description = "Shows a custom message",

  -- Does this mode need wifi?
  needsWifi = false,

  -- Current custom message to print
  text = "\1\n\16Powered by\n\16/dev/tal\n"

}



function mode.activate(self)
	sendToDisplay(self.text)
end



return mode
