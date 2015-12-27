#include <avr/pgmspace.h>
#include "font.h"
#include "font_data.h"
#include "config.h"

extern uint8_t data[];

/* writes the character given by the inputChar character information struct
 * out starting at the row supplied in currentPosition of the data array.
 * It fills currentPosition with the width incremention of the character.
 */
void writeCharacter(struct char_info_t* PROGMEM inputChar,
	uint16_t* currentPosition) {
	int8_t startspace, endspace, space;
	space = pgm_read_byte(&(inputChar->spacing));
	startspace = space >> 4;
	endspace = space & 0x0F;
	if (endspace & 0x08) {
		endspace |= 0xF0;
	}

	uint8_t charwidth = pgm_read_byte(&(inputChar->width));

	if (startspace >= 0 || ((*currentPosition) % TOTAL_ROWS) >= -startspace) {
		uint8_t expEndLine = (*currentPosition + charwidth + startspace) / TOTAL_ROWS;
		if (expEndLine < NUM_LINES && expEndLine != *currentPosition / TOTAL_ROWS) {
			(*currentPosition) = ((*currentPosition / TOTAL_ROWS) + 1) * TOTAL_ROWS;
		} else {
			(*currentPosition) += startspace;
		}
	}

	uint8_t* PROGMEM charPtr = pgm_read_ptr(&(inputChar->fontPtr));

	for (uint8_t i = 0; i < charwidth; i++) {
		uint16_t pos = ((*currentPosition)++)*4;
		if (*currentPosition > TOTAL_ROWS * NUM_LINES) {
			/* Safety feature */
			return;
		}
		data[pos++]	|= pgm_read_byte(charPtr++);
		data[pos++]	|= pgm_read_byte(charPtr++);
		data[pos++]	|= pgm_read_byte(charPtr++);
		data[pos]	|= pgm_read_byte(charPtr++);
	}

	(*currentPosition) += endspace + 1;
}

/* writes the character(s) found first at inputBuffer out starting at the row
 * supplied in currentPosition of the data array.
 * Read until the string's end if onlyOneCharacter is zero.
 * It fills currentPosition with the width incrementation of the character and
 * returns the number of characters which were read in from the inputBuffer.
 */
uint8_t writeUTF8(const char* inputBuffer, uint16_t* currentPosition,
	uint8_t onlyOneCharacter) {
	uint8_t readBytes = 0;
	uint8_t centerCharacters = 0;
	unsigned char chr;

	while ((chr = inputBuffer[readBytes++]) != '\0') {
		if (chr == '\x10') { /* center the current line */
			centerCharacters = 1;
			continue;
		}
		if (chr == '\n') {
			// TODO: Known bugs: last line can not be centered (probably, because \n is not effective there?)
			if(centerCharacters) {
				uint8_t lineWidth = (*currentPosition) % TOTAL_ROWS;
				if(lineWidth < TOTAL_ROWS - 1 && lineWidth > 0) { /* otherwise it cannot be centered */
					uint16_t currentLineOffset = ((*currentPosition) / TOTAL_ROWS) * TOTAL_ROWS;
					uint8_t destinationOffset = (TOTAL_ROWS + lineWidth) / 2;

					/* Center it now */
					for(uint8_t i = destinationOffset + 1; i >= 1; i--) {
						uint16_t dest_pos = (i-1+currentLineOffset)*4;
						if (lineWidth > 0) {
							uint16_t src_pos = (--lineWidth+currentLineOffset)*4;
							data[dest_pos++] = data[src_pos++];
							data[dest_pos++] = data[src_pos++];
							data[dest_pos++] = data[src_pos++];
							data[dest_pos] = data[src_pos];
						} else {
							data[dest_pos++] = 0;
							data[dest_pos++] = 0;
							data[dest_pos++] = 0;
							data[dest_pos] = 0;
						}
					}
				}
			}
			(*currentPosition) = ((*currentPosition / TOTAL_ROWS) + 1) * TOTAL_ROWS;
			centerCharacters = 0;
			continue;
		}
		if (chr >= 0x80) { /* simple UTF-8 */
			uint8_t uc_chr[] = {0, 0};
			if (chr >= 0xC0 && chr < 0xF0) { /* 2 or 3 byte sequence */
				if (chr >= 0xE0) { /* 3 byte sequence */
					uc_chr[0] = chr << 4;
					chr = inputBuffer[readBytes++];
				} else {
					chr &= 0x1f;
				}
				uc_chr[0] |= (chr & 0x7F) >> 2;
				uc_chr[1] = chr << 6;
				chr = inputBuffer[readBytes++];
				uc_chr[1] |= (chr & 0x3F);

				/* find character in map */
				if (uc_chr[0]) {
					for (uint8_t i = 0; i < FONT_CHARS_2B; i++) {
						if (pgm_read_word(&((font_info_2b+i)->chrVal)) ==
							((((uint16_t)uc_chr[0]) << 8) | uc_chr[1])) {
							writeCharacter((struct char_info_t*) (font_info_2b+i),
								currentPosition);
						}
					}
					if (onlyOneCharacter) {
						break;
					}
					continue;
				}
				chr = uc_chr[1];
			}
		}
		/* one byte / ASCII */
		/* find character in map */
		for (uint8_t i = 0; i < FONT_CHARS_1B; i++) {
			if (pgm_read_byte(&((font_info_1b+i)->chrVal)) == chr) {
				writeCharacter((struct char_info_t*) (font_info_1b+i),
					currentPosition);
			}
		}
		if (onlyOneCharacter) {
			break;
		}
	}
	return readBytes;
}