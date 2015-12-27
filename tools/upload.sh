#!/bin/bash


for f in ../nodemcu/*.lua
do
	# echo -e "$f\t$(basename $f)"
#	luamin -f $f > $f.min
#	./upload.lua test.txt $f.min $(basename $f)
	./upload.lua /dev/ttyUSB0 $f $(basename $f) 0.5
	./upload.lua test-$(basename $f).txt $f $(basename $f) 0
	rm -f $f.min
done
