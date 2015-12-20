#ifndef _FONT_H_
#define _FONT_H_

#include <inttypes.h>

struct char_info_t {
	const uint32_t *fontPtr;	/* Pointer to the font data struct containing the
						 * first row of this character */
	uint8_t spacing;	/* Extra spacing before and after the character as
						 * 4-bit two's complement value each.
						 * first 4-bits: spacing before the character
						 * second 4-bits: after the character
						 * A zero value means that the usual spacing is applied
						 * (by default one row).
						 * Example: "0xF0" means that the spacing before the
						 * character is subtracted by one. */
	uint8_t width;		/* The number of rows this character takes on the LCD */
};

struct font_info_1b_t {	/* Font information struct for characters with a length
						 * of one byte encoded in Unicode */
	const uint32_t *fontPtr;	/* Pointer to the font data struct containing the
						 * first row of this character */
	uint8_t spacing;	/* Extra spacing before and after the character as
						 * 4-bit two's complement value each.
						 * first 4-bits: spacing before the character
						 * second 4-bits: after the character
						 * A zero value means that the usual spacing is applied
						 * (by default one row).
						 * Example: "0xF0" means that the spacing before the
						 * character is subtracted by one. */
	uint8_t width;		/* The number of rows this character takes on the LCD */
	uint8_t chrVal;		/* Character value (Unicode) */
};

struct font_info_2b_t {	/* Font information struct for characters with a length
						 * of two bytes encoded in Unicode */
	const uint32_t *fontPtr;	/* Pointer to the font data struct containing the
						 * first row of this character */
	uint8_t spacing;	/* Extra spacing before and after the character as
						 * 4-bit two's complement value each.
						 * first 4-bits: spacing before the character
						 * second 4-bits: after the character
						 * A zero value means that the usual spacing is applied
						 * (by default one row).
						 * Example: "0xF0" means that the spacing before the
						 * character is subtracted by one. */
	uint8_t width;		/* The number of rows this character takes on the LCD */
	uint16_t chrVal;	/* Character value (Unicode) */
};

void writeCharacter(struct char_info_t* PROGMEM inputChar,
	uint16_t* currentPosition);
uint8_t writeUTF8(const char* inputBuffer, uint16_t* currentPosition,
	uint8_t onlyOneCharacter);

#endif
