;
; lab2_1.asm
;
; Created: 2019/10/8 下午 11:54:22
; Author : User
;


; Replace with your application code
.include "m2560def.inc"
.def al=r16
.def ah=r17
.def bl=r18
.def bh=r19

.macro remainder			;for finding remainder
		mov r14, @0
		mov r15, @1
rloop:	
		cp r14, @2
		cpc r15, @3
		brlo remain
		sub r14, @2
		sbc r15, @3
		rjmp rloop
remain:
		mov @4, r14
		mov @5, r15
.endmacro

main:
		rcall gcd

end:
		rjmp end

gcd:
		;Prologue:
		push YL
		push YH
		push r20
		push r21
		in YL, SPL
		in YH, SPH
		sbiw Y, 8
		out SPL, YL
		out SPH, YH
		std Y+1, r19		;pass b
		std Y+2, r18
		std Y+3, r17		;pass a
		std Y+4, r16
		;End of prologue
		
		

		cpi r18, 0			;check b==0 or b!=0
		brne notequal
		cpi r19, 0
		brne notequal
		movw r25:r24, r17:r16
		rjmp endgcd
notequal:
		ldd r16, Y+2		;load b into a
		ldd r17, Y+1
		ldd r20, Y+4
		ldd r21, Y+3
		remainder r20, r21, r16, r17, r18, r19
		rcall gcd
		;end of the function body

endgcd:
		;Epilogue
		adiw Y, 8
		out SPH, YH
		out SPL, YL
		pop r21
		pop r20
		pop YH
		pop YL
		ret					;return to main
		; End of epilogue




		