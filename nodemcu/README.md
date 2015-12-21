 Time
------
Time is calculated by making an HTTP request to a Server and checking the "Date: "-Header.
This is done everytime a Wifi connection is established.
TODO: Implement SNTP.



 Files
-------
 The file layout of this project:

 Filename      | Usage
 ------------- | -----
 init.lua      | executed at the "boot" of the ESP
 config.lua    | generic configuration(timezone, etc)
 tools.lua     | generic tools
 timetools.lua | time related tools
 nettools.lua  | network related tools
 mode_*        | contains a mode


--------------------------------------------------------------------------------


 Timers
--------
 Usage of timers

 Timer | Usage
 ----- | -----
   0   | toggle display mode
   1   | free
   2   | free


--------------------------------------------------------------------------------


 Lua <--> Display interface encoding
-------------------------------------
 our byte subset (of generally supported UTF-8) looks like:

 Hex  | Lua | Description
 ---- | --- | ------------
 0x00 | \0	| end of string
 0x01 | \1	| clear the whole display and set position to start
 0x07 | \a	| -
 0x08 | \b	| backspace the last character
 0x09 | \t	| horizontal tab (tab width may be set to fit all data in tabular form on the display)
 0x0A | \n	| new line (following an automatic carriage return)
 0x0B | \v	| vertical tab (go to the last line directly)
 0x0C | \f  | -
 0x0D | \r  | carriage return (go to the start of line)
 0x10 | \16 | 	center the current line

 0x20 - 0xFF stay common ASCII characters / UTF-8 values
