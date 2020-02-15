; Project code from Chuang-Yin Wang
; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.
;Created: 2019/11/17 0:17:50
  
.include "m2560def.inc"
.def W1=r4
.def W2=r5
.def W3=r6
.def W4=r7

;Port C used for keypad, high 4 bits for column selection, low four bits for reading rows.
;Port A is for LCD conrtrol. Port F is for LCD 
;use Timer 5, Timer 3 as pwm input
;Output waveform:	
;  OC5A ->PL4 in the board	(PL3 in datasheet)
;  OC5B ->PL3 in the board	(PL4 in datasheet)
;  OC5C ->PL2 in the board	(PL5 in datasheet)
;  OC3A ->PE5 in the board	(PE3 in datasheet)
; and the generated pwm signals are connected to LED

.def row    =r16		; current row number
.def col    =r17		; current column number
.def rmask   =r18		; mask for current row
.def cmask	=r19		; mask for current column
.def temp1	=r20		
.def temp2  =r21

.equ PORTCDIR =0xF0			; use PortC for input/output from keypad: PC7-4, output, PC3-0, input
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output
.equ INITROWMASK = 0x01		; scan from the bottom row
.equ ROWMASK  =0x0F			; low four bits are output from the keypad. This value mask the high 4 bits.
.equ W1_PLACE = 0b11000101	; The address of the w1 number in LCD
.equ W2_PLACE = 0b11001000	; The address of the w2 number in LCD
.equ W3_PLACE = 0b11001011	; The address of the w3 number in LCD
.equ W4_PLACE = 0b11001110	; The address of the w4 number in LCD


;Setting tow interrupts in the programs
;The RESET interrupt is activated when the program start or pushing the RESET button
;The EXT_INT0 interrupt is activated when pushing the PB0 button




	jmp RESET						; interrupt vectors
.org INT0addr						; define in m2560def.inc equal 0x0002
	jmp EXT_INT0


.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_lcd_dataRG				;put data using to the LCD from register 
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro place_lcd_data				;first go to the specific address in the lcd and input the data, 
	do_lcd_command @0				;
	do_lcd_data @1
.endmacro

.macro place_lcd_dataRG				;first go to the specific address in the lcd and input the data from Register,
	do_lcd_command @0				;@0 should must be Set DD RAM Address function
	do_lcd_dataRG @1
.endmacro





RESET:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16
	;Keyboard initialized
	ldi temp1, PORTCDIR			; columns are outputs, rows are inputs
	out	DDRC, temp1
	
	;Timer initialized
	;Setting ouput bit for pwm waveform control
	ldi temp1, 0b00111000
	sts DDRL, temp1						;Bit 3 will function as OC5A, Bit 4 OC5B, bit 5 OC5C
	ldi temp1, 0b00001000
	out DDRE, temp1
	clr temp1							;the OCR value controls the PWM duty cycle 
	sts OCR3AH, temp1					;The top value for Phase correct PWM is 0XFF, so set the high bit of OCR to zero
	sts OCR5AH, temp1
	sts OCR5BH, temp1
	sts OCR5CH, temp1
	sts OCR3AL, temp1					;Clear all the LED
	sts OCR5AL, temp1
	sts OCR5BL, temp1
	sts OCR5CL, temp1
	
	; Set Timer5 to Phase Correct PWM mode.
	ldi temp1, (1 << CS50) ; Set Timer clock frequency
	sts TCCR5B, temp1
	ldi temp1, (1<< WGM50)|(1<<COM5A1)|(1<<COM5B1)|(1<<COM5C1)
	sts TCCR5A, temp1
	; Set Timer3 to Phase Correct PWM mode.
	ldi temp1, (1 << CS30) ; Set Timer clock frequency
	sts TCCR3B, temp1
	ldi temp1, (1<< WGM30)|(1<<COM3A1)
	sts TCCR3A, temp1

	;clear the number of each window
	clr W1
	clr W2
	clr W3
	clr W4

	;LCD initialized
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001100 ; Cursor on, bar, no blink

	;do_lcd_command 0b10010000 ;try change direction
	;Initial State setting
	do_lcd_data 'S'
	do_lcd_data ':'
	place_lcd_data 0b10000100, 'W'	;Change direction to w1
	do_lcd_data '1'
	place_lcd_data 0b10000111, 'W'	;Change direction to w2
	do_lcd_data '2'
	place_lcd_data 0b10001010, 'W'	;Change direction to w3
	do_lcd_data '3'
	place_lcd_data 0b10001101, 'W'	;Change direction to w4
	do_lcd_data '4'
	
	place_lcd_data W1_PLACE, '0'
	place_lcd_data W2_PLACE, '0'
	place_lcd_data W3_PLACE, '0'
	place_lcd_data W4_PLACE, '0'

	ldi temp1, (1<<ISC00)			; set INT0 as falling edge triggered interrupt
	sts EICRA, temp1
	in temp1, EIMSK					; enable INT0
	ori temp1, (1<<INT0)
	out EIMSK, temp1
	sei					
	jmp main


EXT_INT0:
	push temp1					;saving conflicted registers
	push temp2
	in temp1, SREG
	push temp1

	clr temp1
	clr w1						;clear all the windows
	clr w2
	clr w3
	clr w4
	subi temp1, -'0'
	place_lcd_dataRG W1_PLACE, temp1
	place_lcd_dataRG W2_PLACE, temp1
	place_lcd_dataRG W3_PLACE, temp1
	place_lcd_dataRG W4_PLACE, temp1
	place_lcd_data 0b10000000, '!'		;if is emergency control, than change to the Alphabet '!'
	clr temp1
	sts OCR3AL, temp1					;Clear all the LED
	sts OCR5AL, temp1
	sts OCR5BL, temp1
	sts OCR5CL, temp1
	rcall sleep_400ms

	;give back the registers saved in the stack
	pop temp1
	out SREG, temp1
	pop temp2
	pop temp1
	reti


main:
	
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column

colloop:
	cpi col, 4
	breq main
	out	PORTC, cmask				; set column to mask value (one column off)
	ldi temp1, 0xFF

delay:
	dec temp1
	brne delay
	in	temp1, PINC				; read PORTC
	andi temp1, ROWMASK
	cpi temp1, 0xF				; check if any rows are on
	breq nextcol

	; if yes, find which row is on
	ldi rmask, INITROWMASK		; initialise row check
	clr	row						; initial row

rowloop:
	cpi row, 4
	breq nextcol
	mov temp2, temp1
	and temp2, rmask			; check masked bit
	breq convert 				; if bit is clear, convert the bitcode
	inc row						; else move to the next row
	lsl rmask					; shift the mask to the next bit
	jmp rowloop

nextcol:
	lsl cmask					; else get new mask by shifting and 
	inc col						; increment column value
	jmp colloop					; and check the next column


;use first two rows for local control. Row 0 will increase the number of the window (darker) whereas
;Row 1 will decrease the number of the window (clearer). each column represents one window.
;Button 7(dark),8(clear) are used for central control.  PB0 is used for emergency.

no_used_pressed:
	jmp main							;if row 3 is pressed

convert:
	cpi row, 3
	breq no_used_pressed				;if row is 3, which does not indicates anything. Then return to scanning again.
	cpi row, 2							; if row  is 2, we have central control
	breq central
	cpi col, 0							; if column is 0 we have W1 local control
	breq w1_jmp				
	cpi col, 1							; if column is 1 we have W2 local control
	breq w2_jmp
	cpi col, 2							; if column is 2 we have W3 local control
	breq w3_jmp						
	cpi col, 3							; if column is 3 we have W4 local control
	breq w4_jmp

w1_jmp:							;because w1_local is too far to rjmp, so using a intermediate jump point
	jmp w1_local
w2_jmp:
	jmp w2_local	
w3_jmp:
	jmp w3_local
w4_jmp:
	jmp w4_local			

central:
	cpi col, 0					;if the keypad pressing is 7, then idicates all dark
	breq central_dark
	cpi col, 1					;if the keypad pressing is 8, then idicates all clear
	breq central_clear	
	jmp main					;if the keypad is not pressing 7 or 8, than return to main
central_dark:
	place_lcd_data 0b10000000, 'C'		;if is central control, than change to the Alphabet 'C'
	ldi temp1, 3
	mov w1, temp1				;store dark in every window
	mov w2, temp1
	mov w3, temp1
	mov w4, temp1
	subi temp1, -'0'
	place_lcd_dataRG W1_PLACE, temp1
	place_lcd_dataRG W2_PLACE, temp1
	place_lcd_dataRG W3_PLACE, temp1
	place_lcd_dataRG W4_PLACE, temp1
	ser temp1
	sts OCR3AL, temp1					;Light up all the LED
	sts OCR5AL, temp1
	sts OCR5BL, temp1
	sts OCR5CL, temp1
	rcall sleep_400ms
	jmp main
central_clear:
	place_lcd_data 0b10000000, 'C'		;if is central control, than change to the Alphabet 'C'
	clr temp1
	mov w1, temp1				;store dark in every window
	mov w2, temp1
	mov w3, temp1
	mov w4, temp1
	subi temp1, -'0'
	place_lcd_dataRG W1_PLACE, temp1
	place_lcd_dataRG W2_PLACE, temp1
	place_lcd_dataRG W3_PLACE, temp1
	place_lcd_dataRG W4_PLACE, temp1
	clr temp1
	sts OCR3AL, temp1					;Clear all the LED
	sts OCR5AL, temp1
	sts OCR5BL, temp1
	sts OCR5CL, temp1
	rcall sleep_400ms
	jmp main	

w1_local:
	cpi row, 0
	breq w1_dark
	ldi temp1, 0
	cp W1, temp1
	breq w1_mainjmp
	dec W1
	mov temp1, W1
	subi temp1, -'0'
	place_lcd_dataRG W1_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W1
	ldi temp2, 63
	mul temp1, temp2
	sts OCR5AL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w1_mainjmp:
	jmp main

w1_dark:
	ldi temp1, 3
	cp W1, temp1
	breq w1_mainjmp
	inc W1
	mov temp1, W1
	subi temp1, -'0'
	place_lcd_dataRG W1_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W1
	ldi temp2, 63
	mul temp1, temp2
	sts OCR5AL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w2_local:
	cpi row, 0
	breq w2_dark
	ldi temp1, 0
	cp W2, temp1
	breq w2_mainjmp
	dec W2
	mov temp1, W2
	subi temp1, -'0'
	place_lcd_dataRG W2_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W2
	ldi temp2, 63
	mul temp1, temp2
	sts OCR5BL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w2_mainjmp:
	jmp main

w2_dark:
	ldi temp1, 3
	cp W2, temp1
	breq w2_mainjmp
	inc W2
	mov temp1, W2
	subi temp1, -'0'
	place_lcd_dataRG W2_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W2
	ldi temp2, 63
	mul temp1, temp2
	sts OCR5BL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w3_local:
	cpi row, 0
	breq w3_dark
	ldi temp1, 0
	cp W3, temp1
	breq w3_mainjmp
	dec W3
	mov temp1, W3
	subi temp1, -'0'
	place_lcd_dataRG W3_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W3
	ldi temp2, 63
	mul temp1, temp2
	sts OCR5CL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w3_mainjmp:
	jmp main

w3_dark:
	ldi temp1, 3
	cp W3, temp1
	breq w3_mainjmp
	inc W3
	mov temp1, W3
	subi temp1, -'0'
	place_lcd_dataRG W3_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W3
	ldi temp2, 63
	mul temp1, temp2
	sts OCR5CL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w4_local:
	cpi row, 0
	breq w4_dark
	ldi temp1, 0
	cp W4, temp1
	breq w4_mainjmp
	dec W4
	mov temp1, W4
	subi temp1, -'0'
	place_lcd_dataRG W4_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W4
	ldi temp2, 63
	mul temp1, temp2
	sts OCR3AL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main

w4_mainjmp:
	jmp main

w4_dark:
	ldi temp1, 3
	cp W4, temp1
	breq w4_mainjmp
	inc W4
	mov temp1, W4
	subi temp1, -'0'
	place_lcd_dataRG W4_PLACE, temp1
	place_lcd_data 0b10000000, 'L'		; if is local control, than change to the Alphabet 'L'
	mov temp1, W4
	ldi temp2, 63
	mul temp1, temp2
	sts OCR3AL, r0						; lighter the LED
	rcall sleep_400ms
	jmp main





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
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

sleep_400ms:
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	rcall sleep_100ms
	ret