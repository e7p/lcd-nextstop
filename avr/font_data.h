#ifndef _FONTDATA_H_
#define _FONTDATA_H_

#include <avr/pgmspace.h>
#include "font.h"

/* 28-Segment LCD Mosaic Font (c) by Endres and Phip */

#define FONT_CHARS_1B	190
#define FONT_CHARS_2B	10

extern const uint32_t PROGMEM font[];
extern const struct font_info_1b_t PROGMEM font_info_1b[];
extern const struct font_info_2b_t PROGMEM font_info_2b[];

#endif
