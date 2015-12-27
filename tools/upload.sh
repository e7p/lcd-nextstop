#!/bin/bash


for f in ../nodemcu/*.lua
do
	# echo -e "$f\t$(basename $f)"
	luamin -f $f > $f.min
	./upload.lua /dev/ttyUSB0 $f.min $(basename $f)
	rm -f $f.min
done
