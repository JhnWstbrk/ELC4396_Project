/*****************************************************************//**
 * @file main_vanilla_test.cpp
 *
 * @brief Basic test of 4 basic i/o cores
 *
 * @author p chu
 * @version v1.0: initial release
 *********************************************************************/

//#define _DEBUG

#include "chu_init.h"
#include "gpio_cores.h"
#include "sseg_core.h"
#include "ps2_core.h"
#include <cmath>

const double LOG_SEMITONE = log(2.0)/12.0;

int getSemitones(double f)
{
	double note = log(f/16.35) / LOG_SEMITONE;
    return (int)round(note);
}
unsigned concatenate(unsigned x, unsigned y) {
    unsigned pow = 10;
    while(y >= pow)
        pow *= 10;
    return x * pow + y;
}

void determineNote(Ps2Core *ps2_p, SsegCore *sseg_p) {
	char key_input;
	char input_freq[7] = {'0','2','6','1','.','6','3'};
	int i = 0;
	int char2Num;
	double freq = 0;
	int semitones = 0;

    ps2_p->init();

	uart.disp("\r\nEnter frequency: ");
	do { // get keyboard input
		if(ps2_p->get_kb_ch(&key_input)) {
			uart.disp(key_input);
			input_freq[i] = key_input;
			i++;
		}
	} while (i < 7);

	for(i = 0; i < 7; i++) {
		if(input_freq[i] != '.') {
			char2Num = input_freq[i] - '0';
			freq = concatenate(freq,char2Num);
		}
	}

	freq = freq / 100;

	semitones = getSemitones(freq);

	int note;
	int accidental = 255;
	int octave;
	static const uint8_t noteArray[12] =
		{0xc6, 0xa1, 0xa1, 0x86, 0x86, 0x8e, 0xc2, 0xc2, 0x88, 0x88, 0x83, 0x83};

	octave = semitones / 12;
	note = semitones % 12;

	sseg_p->write_1ptn(noteArray[note], 3);

	if(note == 1 || note == 3 || note == 6 || note == 8 || note == 10) {
		accidental = 131;
	}

	sseg_p->write_1ptn(accidental, 2);
	sseg_p->write_1ptn(sseg_p->h2s(octave), 1);

}

// instantiate cores
SsegCore sseg(get_slot_addr(BRIDGE_BASE, S8_SSEG));
Ps2Core ps2(get_slot_addr(BRIDGE_BASE, S11_PS2));


int main() {

	while(1) {
		determineNote(&ps2, &sseg);
		sleep_ms(100);
	}

} //main

