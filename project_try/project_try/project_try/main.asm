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
;  OC5A ->PL4 in the board
;  OC5B ->PL3 in the board
;  OC5C ->PL2 in the board
;  OC3A ->PE5 in the board
; and the generated pwm signals are connected to LED


;use first two rows for local control. Row 0 will increase the number of the window (darker) whereas
;Row 1 will decrease the number of the window (clearer). each column represents one window.
;Button 7(dark),8(clear) are used for central control.  PB0 is used for emergency.


.def row    =r16		; current row number
.def col    =r17		; current column number
.def rmask   =r18		; mask for current row
.def cmask	=r19		; mask for current column
.def temp1	=r20		
.def temp2  =r21
.def temp3  =r22
.def temp4  =r23
.def presscount=r24			;the number of local control been pressed

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

.macro give_lcd_number				;using the macro place_lcd_dataRG, show the specific number on specific placce in LCD
	mov temp3, @0
	subi temp3, -'0'
	place_lcd_dataRG @1, temp3
.endmacro

.macro change_pwm					;change the dutyclcle of the the specific pwm waveform
	mov temp3, @0
	ldi temp4, 63
	mul temp3, temp4
	sts @1, r0			
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

	;clear the number of each window and the local control press count
	clr W1
	clr W2
	clr W3
	clr W4
	clr presscount

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
	cpi presscount, 0
	breq no_local				;if there is a local control pressed, then delay for a while
	place_lcd_data 0b10000000, 'L'		; if there is local control pressed, than change to the Alphabet 'L'
	give_lcd_number W1, W1_PLACE;if there are local pressed, then change the lcd and led, and then delay for 400ms
	change_pwm W1, OCR5AL
	give_lcd_number W2, W2_PLACE
	change_pwm W2, OCR5BL
	give_lcd_number W3, W3_PLACE
	change_pwm W3, OCR5CL
	give_lcd_number W4, W4_PLACE
	change_pwm W4, OCR3AL
	rcall sleep_400ms
no_local:
	clr presscount
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column

colloop:
	cpi col, 4
	breq scanfinish
	out	PORTC, cmask				; set column to mask value (one column off)
	ldi temp1, 0xFF
	rjmp delay
scanfinish:
	jmp main

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
	jmp rowloop					 

;;The label below is let the local control is pressed, the branch instruction can jmp to the specific label (rjmp is not enough)
go_central:
	jmp central
go_w1:							;go to whether increase or decrease the value of w1
	jmp w1_local
go_w2:							;go to whether increase or decrease the value of w2
	jmp w2_local
go_w3:							;go to whether increase or decrease the value of w3
	jmp w3_local
go_w4:							;go to whether increase or decrease the value of w4
	jmp w4_local
useless_pressed:
	jmp keepscan				;if row 3 is pressed, ignored and keep scanning

rowloop:
	cpi row, 4
	breq nextcol
	mov temp2, temp1
	and temp2, rmask			; check masked bit
	brne keepscan				;if not equal; keep row scan
	cpi row, 3
	breq useless_pressed		;since row 3 is not used in this project, ignore when the button in this row is pressed
	cpi row, 2
	breq go_central				; if button in row 2 is pressed, go to central control
	inc presscount				;increase the presscount when having local control pressed
	cpi col, 0							; if column is 0 we have W1 local control
	breq go_w1				
	cpi col, 1							; if column is 1 we have W2 local control
	breq go_w2
	cpi col, 2							; if column is 2 we have W3 local control
	breq go_w3					
	cpi col, 3							; if column is 3 we have W4 local control
	breq go_w4
keepscan:	
	inc row						; else move to the next row
	lsl rmask					; shift the mask to the next bit
	jmp rowloop

nextcol:

	lsl cmask					
	inc col						; increment column value
	jmp colloop					; and check the next column




central:
	clr presscount
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
	ldi temp3, 0						
	cp W1, temp3
	breq w1_return						;if w1 is already 0, then no need to decrease
	dec W1								;decrease the number of w1
	
w1_return:
	jmp keepscan

w1_dark:
	ldi temp3, 3
	cp W1, temp3
	breq w1_return						;if w1 is already 3, then no need to increase
	inc W1								;increase the number of w1
	jmp keepscan

w2_local:
	cpi row, 0
	breq w2_dark						
	ldi temp3, 0
	cp W2, temp3
	breq w2_return						;if w2 is already 0, then no need to decrease
	dec W2								;decrease the number of w2

w2_return:
	jmp keepscan

w2_dark:
	ldi temp3, 3
	cp W2, temp3
	breq w2_return						;if w2 is already 3, then no need to increase
	inc W2								;increase the number of w2
	jmp keepscan

w3_local:
	cpi row, 0
	breq w3_dark						
	ldi temp3, 0						
	cp W3, temp3
	breq w3_return						;if w3 is already 0, then no need to decrease
	dec W3								;decrease the number of w3
	
w3_return:
	jmp keepscan

w3_dark:
	ldi temp3, 3
	cp W3, temp3
	breq w3_return						;if w3 is already 3, then no need to increase
	inc W3								;increase the number of w3
	jmp keepscan

w4_local:
	cpi row, 0
	breq w4_dark
	ldi temp3, 0
	cp W4, temp3
	breq w4_return						;if w4 is already 0; then no need to decrease
	dec W4								;decrease the number of w4
	
w4_return:
	jmp main

w4_dark:
	ldi temp3, 3
	cp W4, temp3
	breq w4_return						;if w4 is already 3, then no need to increase
	inc W4								;increase the number of w4
	jmp keepscan
	
	
	
	





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