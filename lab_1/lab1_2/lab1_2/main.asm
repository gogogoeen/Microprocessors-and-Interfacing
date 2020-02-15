;
; lab1_2.asm
;
; Created: 2019/10/2 下午 04:37:41
; Author : Chuang-Yin Wang
;


.include "m2560def.inc" 
.def al=r16				;define low byte of a to be register r16
.def ah=r17				;define high byte of a to be register r17
.def bl=r18				;define low byte of b to be register r18
.def bh=r19				;define high byte of b to be register r19
.macro substract
		sub @0, @1
		sbc @2, @3
		rjmp main
.endmacro

main:
		cp al, bl		;compare a and b low byte
		cpc ah, bh		;compare a and b high byte
		breq end		;go to end if a=b
		brlo biggerb	;brach if b>a
		substract al, bl, ah, bh

biggerb:
		substract bl, al, bh, ah


end:
		rjmp end