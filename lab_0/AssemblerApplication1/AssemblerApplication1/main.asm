;
; AssemblerApplication1.asm
;
; Created: 2019/9/19 下午 02:55:51
; Author : User
;


; Replace with your application code
.include "m2560def.inc" 
ldi r17, 5	;r17=x=9
ldi r18, -2	;r18=y=-2
ldi r16, 2  ;r16=2
mul r16, r17
mov r19, r0
mul r17, r18	
sub r19, r0
mul r17, r17
sub r19, r0	;r19=z

