/*
 * lab4.asm
 *
 *  Created: 2019/11/2 0:17:50
 *   Author: PC
 */ 

 ; OPE -> +5V
 ; OPO -> PORTD RDX4 (INT0)
 ; POT -> MOT
 ; D0-7 (LCD DATA)--> PF0-7
 ; BE-RS (LCD CTRL)--> PA4-7
 .include "m2560def.inc"
 .def count = r17
 .def units = r18
 .def tens = r19
 .def hundreds = r20
 .def temp = r21

 .equ LCD_RS = 7                     ; LCD_RS equal to 7        
 .equ LCD_E = 6                      ; LCD_E equal to 6
 .equ LCD_RW = 5                     ; LCD_RW equal to 5
 .equ LCD_BE = 4                     ; LCD_BE equal to 4

 .macro lcd_set
	sbi PORTA, @0                   ; set pin @0 of port A to 1
 .endmacro

 .macro lcd_clr
	cbi PORTA, @0                   ; clear pin @0 of port A to 0
 .endmacro

 .macro do_lcd_command          ; transfer command to LCD
	ldi r16, @0                 ; load data @0 to r16
	rcall lcd_command           ; rcall lcd_command
	rcall lcd_wait              ; rcall lcd_wait
.endmacro

.macro do_lcd_data              ; transfer data to LCD
	mov r16, @0                 ; move data @0 to r16
	rcall lcd_data              ; rcall lcd_data
	rcall lcd_wait              ; rcall lcd_wait
.endmacro


	jmp RESET						; interrupt vectors
.org INT0addr					; define in m2560def.inc equal 0x0002
	jmp EXT_INT0

RESET:

	 ldi r16, low(RAMEND)			; RAMEND : 0x21FF       
	 out SPL, r16					; initial stack pointer Low 8 bits
	 ldi r16, high(RAMEND)			; RAMEND: 0x21FF
	 out SPH, r16					; initial High 8 bits of stack pointer

									; LCD initalization
	 ser r16						; set r16 to 0xFF
	 out DDRF, r16					; set PORT F to input mode
	 out DDRA, r16					; set PORT A to input mode
	 clr r16						; clear r16
	 out PORTF, r16					; out 0x00 to PORT F
	 out PORTA, r16					; out 0x00 to PORT A

	 do_lcd_command 0b00111000		; 2x5x7
	 rcall sleep_5ms
	 do_lcd_command 0b00111000		; 2x5x7
	 rcall sleep_1ms
	 do_lcd_command 0b00111000		; 2x5x7
	 do_lcd_command 0b00111000		; 2x5x7
	 do_lcd_command 0b00001000 		; display off
	 do_lcd_command 0b00000001 		; clear display
	 do_lcd_command 0b00000110 		; increment, no display shift
	 do_lcd_command 0b00001100

	 ldi temp, (2<<ISC00)			; set INT0 as falling edge triggered interrupt
	 sts EICRA, temp
	 in temp, EIMSK					; enable INT0
	 ori temp, (1<<INT0)
	 out EIMSK, temp
	 sei							; enable the global interrupt 
	 clr count						; clear counters
	 clr units
	 clr tens
	 clr hundreds                         
	 jmp main


EXT_INT0:							; external interrupt
	cpi count, 4					; 4 holes, count 4 one round
	brne inc_count					
	clr count

	cpi units, 9					; if got 9, tens plus 1, clear units
	brne inc_units
	clr units

	cpi tens, 9						; if got 9, hundreds plus 1, clear tens
	brne inc_tens
	clr tens

	cpi hundreds, 9					; if got 9, hundreds plus 1
	brne inc_hundreds
	clr hundreds
	jmp  end_int

inc_count:
	inc count						; count++
	rjmp end_int

inc_units:
	inc units						; units++
	rjmp end_int

inc_tens:
	inc tens						; tens++
	rjmp end_int

inc_hundreds:
	inc hundreds					; hundreds++
	rjmp end_int

end_int:
	reti							; return


main:

	rcall sleep_1s					; wait 1s, speed unit = r/s
	do_lcd_command 0b00000001		; clear display, refresh every second
	cpi hundreds, 0					; if speed < 100, wont display hundreds
	brne display_hundreds			; else display hundreds
	cpi tens, 0						; if speed < 10, wont display tens
	brne display_tens				; else display tens
	rjmp display_units				; display units
	

display_hundreds:
	subi hundreds, -'0'				; add the value of ascii '0' to get speed					  
	do_lcd_data hundreds			; display hundreds

display_tens:
	subi tens, -'0'					; add the value of ascii '0' to get speed
	do_lcd_data tens				; dispaly tens

display_units:
	subi units, -'0'				; add the value of ascii '0' to get speed
	do_lcd_data units				; display units

	ldi temp, 'r'                   ; display "rps"
	do_lcd_data temp 
	ldi temp, 'p'
	do_lcd_data temp 
	ldi temp, 's'
	do_lcd_data temp 

	clr units                       ; clear units
	clr tens						; clear tens
	clr hundreds					; clear hundreds	
	rjmp main						; jump to main

;
; Send a command to the LCD (r16)
;

lcd_command:                        ; send a command to LCD IR
	out PORTF, r16
	nop
	lcd_set LCD_E                   ; use macro lcd_set to set pin 7 of port A to 1
	nop
	nop
	nop
	lcd_clr LCD_E                   ; use macro lcd_clr to clear pin 7 of port A to 0
	nop
	nop
	nop
	ret

lcd_data:                           ; send a data to LCD DR
	out PORTF, r16                  ; output r16 to port F
	lcd_set LCD_RS                  ; use macro lcd_set to set pin 7 of port A to 1
	nop
	nop
	nop
	lcd_set LCD_E                   ; use macro lcd_set to set pin 6 of port A to 1
	nop
	nop
	nop
	lcd_clr LCD_E                   ; use macro lcd_clr to clear pin 6 of port A to 0
	nop
	nop
	nop
	lcd_clr LCD_RS                  ; use macro lcd_clr to clear pin 7 of port A to 0
	ret

lcd_wait:                            ; LCD busy wait
	push r16                         ; push r16 into stack
	clr r16                          ; clear r16
	out DDRF, r16                    ; set port F to output mode
	out PORTF, r16                   ; output 0x00 in port F 
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E                    ; use macro lcd_set to set pin 6 of port A to 1
	nop
	nop
    nop
	in r16, PINF                     ; read data from port F to r16
	lcd_clr LCD_E                    ; use macro lcd_clr to clear pin 6 of port A to 0
	sbrc r16, 7                      ; Skip if Bit 7 in R16 is Cleared
	rjmp lcd_wait_loop               ; rjmp to lcd_wait_loop
	lcd_clr LCD_RW                   ; use macro lcd_clr to clear pin 7 of port A to 0
	ser r16                          ; set r16 to 0xFF
	out DDRF, r16                    ; set port F to input mode
	pop r16                          ; pop r16 from stack
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:                                   ; sleep 1ms
	push r24                                 ; push r24 to stack
	push r25                                 ; push r25 to stack
	ldi r25, high(DELAY_1MS)                 ; load high 8 bits of DELAY_1MS to r25
	ldi r24, low(DELAY_1MS)                  ; load low 8 bits of DELAY_1MS to r25
delayloop_1ms:
	sbiw r25:r24, 1                          ; r25:r24 = r25:r24 - 1
	brne delayloop_1ms                       ; branch to delayloop_1ms
	pop r25                                  ; pop r25 from stack
	pop r24                                  ; pop r24 from stack
	ret

sleep_5ms:                                    ; sleep 5ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	ret
sleep_25ms:

	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret

sleep_100ms:

	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	ret

sleep_500ms:

	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	ret

sleep_1s:
	rcall sleep_500ms
	rcall sleep_500ms
	ret