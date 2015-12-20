# lcd-nextstop
Software for a special type of LCD displays typically used in public transportation. These LCD matrices consist of a mosaic segment matrix.

# Hardware
The Hardware used for now is an ESP8266, which handles all the WIFI stuff and does generate the content which will be displayed on screen.
This is temporarily connected to an AVR microcontroller, which does the translation from serial data to the LCD matrix, which can be controlled per-pixel by the microcontroller. Until now, for simplicity we use an Arduino for that, which will definitely not be the final state of this project.

The general idea is, that in long term, the AVR may be ommited, such that the ESP8266 handles both network data and also the hardware communication.
Usual ESP8266-Boards (ESP-12E) do have actually enough I/O-pins available, such that this should generally be no problem.
One single problem is to find out, whether the LCD screens do work with a 3.3 volts power supply or signal level.
If not, level shifters may be added to the hardware.

## Connection to the displays

The communication to the display modules is done via synchronous serial signals. For that, each module is controlled by its pins `STB` (Strobe), `DI` (Data input) and `CL` (Clock). As we want to keep the number of used pins as low as possible, we use only one `DI`, `CL` pair connected to all modules and control which module is currently active using the specific `STB` pin.

Furthermore, the modules apparently need 5 volts power supply for the LCD drivers and also the logic which decodes the serial signal.
Last but not least, the operating frequency of 256Hz (or maybe 512Hz for newer modules) for the display (supposedly with which the LCD refresh is triggered) must also be provided at the pin `FR`. Otherwise the display could take damage, eventhough we did not really try that out for a longer period of time, as a output compare pin of the AVR in cooperation with an accordingly configured timer is used all the time.

# Repository
This repository consists of different sub-directories, which are all important for themselves.
* avr: the AVR C source code, which is needed until now for the direct communication with the LCD matrix
* nodemcu: the NodeMCU LUA code, which is used for the content which will be displayed on the screen
* tools: useful tools for e.g. generating a C font file out of an svg

# Software
For now, the code of the AVR is written in C and the code for the ESP8266 is written in LUA.
In future, this could change, such that some hardware functionalities for the ESP8266 (in case the AVR would be ommited) may be added in C which could either result in a forked NodeMCU firmware, or in a firmware for the ESP8266 from scratch.

The Software is for now able to display some information like static text and the current time, which is fetched from a web server first.