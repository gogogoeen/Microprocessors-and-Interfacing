;use Timer 5, Timer 3 as pwm input
;Output waveform:	
;  OC5A ->PL4 in the board
;  OC5B ->PL3 in the board
;  OC5C ->PL2 in the board



.include "m2560def.inc"
.def temp=r16
	ldi temp, 0b00111000
	sts DDRL, temp ; Bit 3 will function as OC5A, Bit 4 OC5B, bit 5 OC5C
	ldi temp, 0b00001000
	out DDRE, temp
	clr temp ; the value controls the PWM duty cycle
	sts OCR3AH, temp
	sts OCR5AH, temp
	sts OCR5BH, temp
	sts OCR5CH, temp
	ldi temp, 0xFF									;why highlow ;timer one time how many pwm  ;can timer be output sametime
	sts OCR5AL, temp
	ldi temp, 0X44
	sts OCR5BL, temp
	ldi temp, 0x11								;why highlow ;timer one time how many pwm  ;can timer be output sametime
	sts OCR5CL, temp
	ldi temp, 0xFF								;why highlow ;timer one time how many pwm  ;can timer be output sametime
	sts OCR3AL, temp

	; Set Timer5 to Phase Correct PWM mode.
	ldi temp, (1 << CS50) ; Set Timer clock frequency
	sts TCCR5B, temp.
	ldi temp, (1<< WGM50)|(1<<COM5A1)|(1<<COM5B1)|(1<<COM5C1)
	sts TCCR5A, temp
	; Set Timer3 to Phase Correct PWM mode.
	ldi temp, (1 << CS30) ; Set Timer clock frequency
	sts TCCR3B, temp.
	ldi temp, (1<< WGM30)|(1<<COM3A1)
	sts TCCR3A, temp
end: 
	rjmp end