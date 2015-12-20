#!/usr/bin/env python3
"""svg2font.py -- converts a LCD SVG file into a binary format compatible with
                   the C code for the LCD matrix

Usage: ./svg2font.py [options] filename.svg

Options:
  -n name           Sets the name of the output array variable.
  -f fontinfo.txt   Uses a font information file to generate a LCD font from
                    the input SVG file.
  -h                Shows this help."""
import os.path
import sys
import xml.etree.ElementTree as etree
import math
from svg.path import parse_path
import operator
import getopt

segmentdict = {
	(0, 0):		0,
	(1, 1):		9,
	(2, 0):		8,
	(0, 3):		1,
	(1, 2):		2,
	(2, 3):		10,
	(0, 4):		4,
	(1, 5):		12,
	(2, 4):		11,
	(0, 7):		5,
	(1, 6):		13,
	(2, 7):		6,
	(0, 8):		7,
	(1, 9):		15,
	(2, 8):		14,
	(0, 11):	31,
	(1, 10):	23,
	(2, 11):	22,
	(0, 12):	30,
	(1, 13):	29,
	(2, 12):	21,
	(0, 15):	28,
	(1, 14):	20,
	(2, 15):	19,
	(1, 16):	27,
	(0, 18):	26,
	(1, 17):	18,
	(2, 18):	17
}

def main():
	generateFont = False
	name = "imageData"

	opts, operands = getopt.getopt(sys.argv[1:], "hn:f:")
	for o,v in opts:
		if o == "-n": name = v
		elif o == "-h":
			print(__doc__)
			return
		elif o == "-f":
			fontinfofile = v
			generateFont = True

	if len(operands) != 1 or not os.path.isfile(operands[0]):
		print("Error: you must specify exactly one input file", file=sys.stderr)
		sys.exit(1)

	if generateFont and not os.path.isfile(fontinfofile):
		print("Error: for font generation you must specify a font info text document", file=sys.stderr)
		sys.exit(1)

	file = open(operands[0], "r")
	tree = etree.parse(file)
	elem = tree.getroot()

	cols = math.ceil(float(elem.attrib.get("viewBox").split(' ')[2])/24)
	data = [0] * cols

	g = elem.find('{http://www.w3.org/2000/svg}g')
	if 'translate' in g.attrib['transform']:
		(xoff, yoff) = map(float, (g.attrib['transform'].split('(')[1].split(')')[0].split(',')))
	else:
		(xoff, yoff) = (0.0, 0.0)

	def getRealImagPlusOffset(compl):
		return (compl.real + xoff, compl.imag + yoff)

	bitcount = 0

	for child in g.findall('{http://www.w3.org/2000/svg}path'):
		coords = set()
		for l in parse_path(child.attrib['d']):
			coords.add(getRealImagPlusOffset(l.start))
			coords.add(getRealImagPlusOffset(l.end))
		sumx = 0
		sumy = 0
		count = 0
		for p in coords:
			sumx = sumx + p[0]
			sumy = sumy + p[1]
			count = count + 1
		color = 1 if child.attrib['style'].split('fill:')[1].split(';')[0] == '#00ff00' else 0
		coord = (sumx/count, sumy/count)
		seg = math.floor(coord[0] / 24)
		coord = (math.floor((coord[0] - seg * 24) * 3 / 24), math.floor(coord[1] / 7)) # normalize coord
		if color == 1:
			data[seg] = data[seg] | (1 << segmentdict[coord])
			bitcount = bitcount + 1

	if generateFont:
		ffh = open(fontinfofile, "r")
		linecount = 0
		col = 0
		fontdata = []
		fontinfomap = {}
		lastendspace = 0
		for line in ffh:
			linecount = linecount + 1
			if line.startswith("0x"):
				(hexcode, char, startspace, endspace, width) = line.split("\t")
				startspace = int(startspace)
				endspace = int(endspace)
				width = int(width)
				charCode = int(hexcode[2:], 16)
				if not chr(charCode) == char:
					print("Error in Font info file in line " + str(linecount) + ": The first column hexadecimal value (" + hexcode + ") does not match the Unicode character in the second column (" + char + ", should be " + chr(charCode) + ").", file=sys.stderr)
					sys.exit(3)
				if width != 0:
					if (lastendspace if lastendspace < 0 else 0) + (startspace if startspace < 0 else 0) >= 0 and col > 0:
						# empty col needed
						if data[col] == 0:
							col = col + 1
						else:
							print("Error in font SVG, you need exactly one space in between each character which has no negative spacing in between each other. (Error before character " + hexcode + " defined in line " + str(linecount) + " in the font info file).", file=sys.stderr)
							sys.exit(4)
					lastendspace = endspace
				byteCount = math.ceil(math.log(charCode, 2) / 8)
				if byteCount not in fontinfomap:
					fontinfomap[byteCount] = []
				fontinfomap[byteCount].append((charCode, len(fontdata), startspace, endspace, width, line))
				for i in range(width):
					if data[col] == 0:
						print("Notice: extra spacing character found in column " + str(col) + " in the font SVG.", file=sys.stderr)
					fontdata.append(data[col])
					col = col + 1
		#print(fontinfomap)
		data = fontdata

	if generateFont:
		print("#include \"font_data.h\"\n")

	print("const uint32_t PROGMEM " + name + "[] = {")
	count = len(data)
	for d in data:
		count = count - 1
		print("\t0x" + ('0000000' + (hex(d)[2:]))[-8:].upper() + ("" if count == 0 else ","))
		for x in range(32):
			if d & (1 << x):
				bitcount = bitcount - 1
	print("};")

	if generateFont:
		for n, v in fontinfomap.items():
			print("\nconst struct font_info_" + str(n) + "b_t PROGMEM " + name + "_info_" + str(n) + "b[] = {")
			count = len(v)
			for i in v:
				count = count - 1
				if not -8 <= i[2] <= 7:
					print("Error: Additional start spacing needs to be between -8 and 7 (in line " + str(i[5]) + " of the font info file).", file=sys.stderr)
					sys.exit(5)
				if not -8 <= i[3] <= 7:
					print("Error: Additional end spacing needs to be between -8 and 7 (in line " + str(i[5]) + " of the font info file).", file=sys.stderr)
					sys.exit(6)
				spacingbyte = (((i[2] + 16) & 0x0F) << 4) | ((i[3] + 16) & 0x0F)
				if not 0 <= i[4] <= 255:
					print("Error: Character width needs to be between 0 and 255 (in line " + str(i[5]) + "of the font info file).", file=sys.stderr)
					sys.exit(7)
				print("\t{" +
					name + ("+" + str(i[1]) if i[1] > 0 else "") + ", " +
					"0x" + ("00" + (hex(spacingbyte)[2:]))[-2:].upper() + ", " +
					str(i[4]) + ", " +
					"0x" + ("00" * n + (hex(i[0])[2:]))[-2*n:].upper() +
					"}" + ("" if count == 0 else ","))
			print("};")

	if bitcount != 0:
		print("Checksum test failed, please check your SVG file! (Final bitcount not zero but " + str(bitcount) + ")", file=sys.stderr)
		sys.exit(2)

	if generateFont:
		print("Font build finished! Please copy now the two following lines into your font_data.h file:", file=sys.stderr)
		print("#define FONT_CHARS_1B	" + str(len(fontinfomap[1])), file=sys.stderr)
		print("#define FONT_CHARS_2B	" + str(len(fontinfomap[2])), file=sys.stderr)

if __name__ == "__main__":
    main()