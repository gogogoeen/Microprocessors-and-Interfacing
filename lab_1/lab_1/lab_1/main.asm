;
; lab_1.asm
;
; Created: 2019/9/25 下午 03:29:30
; Author : Chuang-Yin Wang
;


; Replace with your application code
.include "m2560def.inc" 
.def strH=r16
.def strL=r17
.def H=r18
.def L=r19
.def result=r20
.def const=r21

main:
	sbrc strH, 7		;check the string is decimal or hexadecimal
	rjmp hex
	mov H, strH
	mov L, strL
	subi H, 48			;change the ascii-code of high-digit to integer number
	ldi const, 10
	mul H, const		;for decimal high-digit number*10
	mov result, r0
	subi L, 48			;change the ascii-code of low-digit to integer number
	add result, L		;add the result for the decimal mode. Result=10*H+L
	rjmp halt
	
hex:					;if the 7-bit of the high-digit is set move to here. Hexadicemal
	mov H, strH			
	mov L, strL
	subi H, 128			;clear the set bit of the high-digit
	cpi H, 58			;check the high-digit is bigger than 9 or not
	brsh HB
	subi H, 48			;if the high-digit is 0~9. change ascii-code to integer number
	ldi const, 16		
	mul H, const		;high-digit*16
	mov result, r0
	rjmp hexLOW

HB:						;if the high-digit is A~F
	subi H, 55			;change the ascii code to int
	ldi const, 16
	mul H, const		;high-digit*16
	mov result, r0

hexLOW:
	cpi L, 58			;check the low-digit is bigger than 9 or not
	brsh LB
	subi L, 48			;if low-digit is 0~9. Change the ascii code to int
	rjmp hexADD
LB:
	subi L, 55			;if low-digit is A~F. Change the ascii code to int
hexADD:	
	add result, L		;add the result for the hexadecimal mode. Result= 16*H+L
halt:
	rjmp halt
	
