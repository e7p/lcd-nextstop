#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#define BAUD 9600
#include <util/setbaud.h>
#include "config.h"
#include "font.h"

uint8_t data[NUM_LINES*TOTAL_ROWS*4];

const uint8_t linePins[NUM_LINES] = {
	PD4, PD5, PD6, PD7
};

const uint32_t PROGMEM devtallogo[] = {
	0x00080000,
	0x30700000,
	0xC080C040,
	0x00003CA0,
	0xE0F8C056,
	0x101020A0,
	0xF0F8FCF6,
	0x00000000,
	0xE0F8C040,
	0x90D82060,
	0x90D080A0,
	0x00000000,
	0x00E0E0E0,
	0xE0700000,
	0xC088E0E0,
	0x30700000,
	0xC080C040,
	0x00003CA0,
	0x00000056,
	0xE0F8FCE0,
	0x10102020,
	0x20580040,
	0x90902060,
	0xF0F880A0,
	0x00000000,
	0xE0F8FCF6,
	0x10100000
};

void sendbyte(uint8_t b) {
	for(uint8_t i = 0; i < 8; i++) {
		if (b & 0x01) { // if bit is 1
			PORTD |= 0x04;
		} else {
			PORTD &= ~0x04;
		}
		b >>= 1;
		PORTD |= 0x08;
		PORTD &= ~0x08;
	}
}

void sendnibble(uint8_t n) {
	for(uint8_t i = 0; i < 4; i++) {
		if (n & 0x01) { // if bit is 1
			PORTD |= 0x04;
		} else {
			PORTD &= ~0x04;
		}
		n >>= 1;
		PORTD |= 0x08;
		PORTD &= ~0x08;
	}
}

void clear() {
	for(uint16_t i = 0; i < NUM_LINES*TOTAL_ROWS*4; i++) {
		data[i] = 0x00;
	}
}

volatile uint8_t charBuffer[128];
volatile uint8_t charBufferWrite = 0;
uint8_t charBufferRead = 0;

ISR(USART_RX_vect) {
	charBuffer[charBufferWrite++] = UDR0;
	if(charBufferWrite == 128) {
		charBufferWrite = 0;
	}
}

int main() {
	TCNT1 = 0;
	#if F_CPU == 16000000
		OCR1A = 31250; //62500
	#elif F_CPU == 8000000
		OCR1A = 15625; //31250
	#else
		#error Timer Configuration not defined for other frequencies.
	#endif
	TCCR1A |= (1 << COM1A0);
	TCCR1B |= (1 << WGM12) | (1 << CS10);
	DDRD = 0xFC; // PD2 = Data, PD3 = Clock, PD4-7 = Strobe Lines
	DDRB = 0x02; // PB1 = 256 Hz Clock

	UBRR0 = UBRR_VALUE;
	#if USE_2X
		UCSR0A |= (1 << U2X0);
	#else
		UCSR0A &= ~(1 << U2X0);
	#endif
	cli();
	UCSR0B |= (1 << RXEN0) | (1 << RXCIE0); // | (1 << TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
	sei();

	uint8_t segbyte, lastbyte = 0x00, databyte;
	//uint16_t x = 0;

	uint8_t logowidth = sizeof(devtallogo) / 4;
	uint8_t logobegin = (TOTAL_ROWS - logowidth) / 2;

	for(uint16_t i = 0; i < TOTAL_ROWS*4; i++) {
		/*uint8_t v = i % 32;
		*(((uint32_t*)data)+i) = ((uint32_t)1) << v;*/
		for(uint8_t l = 0; l < NUM_LINES; l++) {
			if(i / 4 >= logobegin && i / 4 < logobegin + logowidth) {
				data[l*TOTAL_ROWS*4+i] = pgm_read_byte(((uint8_t*)devtallogo)+i-logobegin*4);
			} else {
				data[l*TOTAL_ROWS*4+i] = 0x00;
			}
		}
	}

	char strbuf[128];
	uint8_t strbuf_len = 0;
	strbuf[0] = '\0';

	while (1) {
		uint16_t pos = 0;
		for(uint8_t l = 0; l < NUM_LINES; l++) {
			for(uint8_t i = 0; i < 4; i++) {
				segbyte = 0x60 | (i << 2);
				for(uint8_t j = 0; j < 4; j++) {
					for(uint8_t k = 0; k < 25; k++) {
						lastbyte = databyte;
						if (k < 25)
							databyte = data[(95-j*24-k)*4+i+TOTAL_ROWS*4*l];
						if (k < 20) {
							sendbyte(databyte);
						} else if (k == 20) {
							sendnibble(0x00);
							sendnibble(databyte & 0x0F);
						} else if (k < 24) {
							sendnibble((lastbyte >> 4) & 0x0F);
							sendnibble(databyte & 0x0F);
						} else { // k == 24
							sendnibble((lastbyte >> 4) & 0x0F);
							sendnibble(0x00);
						}
						if (k % 5 == 4) {
							sendbyte(segbyte);
						}
					}
				}
				PORTD |= (1 << linePins[l]);
				PORTD &= ~(1 << linePins[l]);
			}
		}

		while(charBufferWrite == charBufferRead) {} /* wait for new Characters */
		while(charBufferWrite != charBufferRead) {
			uint8_t c = charBuffer[charBufferRead++];
			if(charBufferRead == 128) {
				charBufferRead = 0;
			}
			switch(c) {
				case 0x01: // clear the whole display and set position to start
					strbuf[0] = '\0';
					strbuf_len = 0;
					break;

				case 0x7F: case 0x08:
					if(strbuf_len > 0) {
						strbuf[--strbuf_len] = '\0';
					}
					break;

				case 0x0D:
					c = '\n';

				default:
					if(strbuf_len < 126 && (c >= 0x10 || c == '\n')) {
						strbuf[strbuf_len++] = c;
						strbuf[strbuf_len] = '\0';
					}
			}
		}

		clear();
		writeUTF8(strbuf, &pos, 0);
	}

	return 0;
}