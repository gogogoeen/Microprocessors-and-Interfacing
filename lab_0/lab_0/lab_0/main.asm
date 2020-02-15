;
; lab_0.asm
;
; Created: 2019/9/19 上午 12:43:23
; Author : User
;


; Replace with your application code
.include "m2560def.inc"
.def a =r16 ; define a to be register r16
.def b =r17 ; define b to be register r17
.def c =r10 ; define c to be register r10
main: ; main is a label
	ldi a, 10 ; load value 10 into a
	ldi b, -20
	lsl a ; 2*a
	add a, b ; 2*a+b
	mov c, a ; c = 2*a+b
halt:
	rjmp halt ; halt the processor execution
