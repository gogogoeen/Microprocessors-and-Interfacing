;
; lab2_try.asm
;
; Created: 2019/10/17 上午 12:08:07
; Author : User
;


; Replace with your application code
.include "m2560def.inc"

.equ loop_count = 666667
.def i3 = r19
.def i2 = r25
.def i1 = r24
.def count3 = r22
.def count2 = r21
.def count1 = r20

.macro halfSecondDelay
	ldi count1, low(loop_count) ; 1 cycle
	ldi count2, high(loop_count)
	ldi count3, byte3(loop_count)
	clr i1 ; 1
	clr i2
	clr i3
	clr r12
loop: 
	
pressloop:
	sbis PINF, 7
	rjmp pressloop

	cp i1, count1 ; 1
	cpc i2, count2
	cpc i3, count3
	brsh done ; 1, 2 (if branch)
	adiw i2:i1, 1 ; 2
	adc i3, r12
	nop
	rjmp loop ; 2
done:
.endmacro

	cbi DDRF, 7
	ser r16
	out DDRC, r16 ; set Port C for output
	sbi PINF, 7
	cbi PINB, 0
main:
	
	ldi r16, 0xC0 ; write the pattern
	out PORTC, r16
	halfSecondDelay
	ldi r16, 0x18
	out PORTC, r16
	halfSecondDelay
	ldi r16, 0x03
	out PORTC, r16
	halfSecondDelay
	rjmp main

end:
	rjmp end