;
; lab3_1.asm
;
; Created: 2019/10/31 下午 05:51:22
; Author : Chuang-Yin Wang
;


; Replace with your application code
.include "m2560def.inc"
	
.def row    =r22		; current row number
.def col    =r17		; current column number
.def rmask  =r18		; mask for current row
.def cmask	=r19		; mask for current column
.def temp1	=r20		
.def temp2  =r21
.equ loop_count = 600000
.def i1 = r26
.def i2 = r27
.def i3 = r13
.def count1 = r23
.def count2 = r24
.def count3 = r25
.def a = r10
.def b = r11
.def ten = r9
.def hundred = r8
.def zzero =r7
;r28 has been used for c and moving r1
.equ PORTFDIR =0xF0			; use PortD for input/output from keypad: PF7-4, output, PF3-0, input
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output
.equ INITROWMASK = 0x01		; scan from the bottom row
.equ ROWMASK  =0x0F			; low four bits are output from the keypad. This value mask the high 4 bits.

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

.macro do_lcd_dataRG
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

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

.macro PressDelay
	ldi count1, low(loop_count) ; 1 cycle
	ldi count2, high(loop_count)
	ldi count3, byte3(loop_count)
	clr i1 ; 1
	clr i2
	clr i3
	clr r12
Pressloop: 
	
	cp i1, count1 ; 1
	cpc i2, count2
	cpc i3, count3
	brsh done ; 1, 2 (if branch)
	adiw i2:i1, 1 ; 2
	adc i3, r12
	nop
	rjmp Pressloop ; 2
done:
.endmacro


;rjmp	RESET

;F use for KEYPAD
;C use for LCD
;A use for LCD control
;E use for LED control
RESET:

	ldi temp1, PORTFDIR			; columns are outputs, rows are inputs
	out	DDRF, temp1
	ser temp1					; PORTC is outputs
	out DDRC, temp1				
	out DDRA, temp1				; PORTA is outputs

	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16
	
	ldi r16, 10
	mov ten, r16
	ldi r16, 100
	mov hundred, r16
	clr zzero

	clr r16
	clr a
	clr b
	out PORTC, r16
	out PORTA, r16

	

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	


main:
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column
colloop:
	cpi col, 4
	breq main
	out	PORTF, cmask				; set column to mask value (one column off)
	ldi temp1, 0xFF
delay:
	dec temp1
	brne delay

	in	temp1, PINF				; read PORTD
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
	and temp2, rmask				; check masked bit
	breq convert 				; if bit is clear, convert the bitcode
	inc row						; else move to the next row
	lsl rmask					; shift the mask to the next bit
	jmp rowloop

nextcol:
	lsl cmask					; else get new mask by shifting and 
	inc col						; increment column value
	jmp colloop					; and check the next column

convert:
	cpi col, 3					; if column is 3 we have a letter
	breq letters				
	cpi row, 3					; if row is 3 we have a symbol or 0
	breq symbols
	mov temp1, row				; otherwise we have a number in 1-9
	lsl temp1
	add temp1, row				; temp1 = row * 3
	add temp1, col				; add the column address to get the value
	subi temp1, -1				; add the value of character '0'
	mul b, ten
	mov r28, r1
	cpi r28, 0
	brne ovr				;if b*10 is overflow
	mov b, r0
	add b, temp1			;b=10*b(last time)+templ1
	brcs ovr				;if b is over flow
	subi temp1, -'0'
	jmp convert_end

letters:
	ldi temp1, 'A'
	add temp1, row				; increment the character 'A' by the row value
	jmp convert_end
ovr:
	jmp overflow
symbols:
	cpi col, 0					; check if we have a star
	breq star
	cpi col, 1					; or if we have zero
	breq zero					
	ldi temp1, '#'				; if not we have hash
	mul a, b
	mov r28, r1
	cpi r28, 0
	brne ovr
	mov r28, r0
	jmp result
star:
	ldi temp1, '*'				; set to star
	mov a, b				;move b to a
	clr b
	jmp convert_end
zero:
	ldi temp1, '0'				; set to zero
	mul b, ten
	mov r28, r1
	cpi r28, 0		
	brne ovr
	mov b, r0
	jmp convert_end

convert_end:
	do_lcd_dataRG temp1			; write value to PORTC
	PressDelay
	jmp main					; restart main loop


;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTC, r16
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
	out PORTC, r16
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
	out DDRC, r16
	out PORTC, r16
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in r16, PINC
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRC, r16
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

overflow:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data 'O'
	do_lcd_data 'V'
	do_lcd_data 'E'
	do_lcd_data 'R'
	do_lcd_data 'F'
	do_lcd_data 'L'
	do_lcd_data 'O'
	do_lcd_data 'W'
	ser temp1					; PORTl is outputs for LED
	out DDRG, temp1	
	out PORTG,temp1
	PressDelay
	clr temp1
	out PORTG, temp1
	PressDelay
	ser temp1
	out PORTG, temp1
	PressDelay
	clr temp1
	out PORTG, temp1
	PressDelay
	ser temp1
	out PORTG, temp1
	PressDelay
	clr temp1
	out PORTG, temp1	
		
	jmp end

result:
	do_lcd_command 0b00000001 ; clear display
	clr count1							;take count1 count2 count3 in use
	clr count2
	clr count3
	
	;subi count1, -1
	;subi count1, -'0'
	;do_lcd_dataRG count1
	rjmp hundredcount
	
hundredcount:
	cp r28, hundred
	;do_lcd_data 'Q'
	brlo tencount
	subi r28,100
	subi count3, -1
	rjmp hundredcount
	
tencount:	
	cp r28,ten
	;do_lcd_data 'V'
	
	brlo onecount
	subi r28, 10
	subi count2, -1
	rjmp tencount

onecount:
	cp r28,zzero
	;do_lcd_data 'A'
	
	breq hundredprint
	subi r28, 1
	subi count1, -1
	rjmp onecount 

hundredprint:
	cpi count3, 0
	breq tenprint
	subi count3, -'0'
	do_lcd_dataRG count3
	subi count2, -'0'
	do_lcd_dataRG count2
	subi count1, -'0'
	do_lcd_dataRG count1
	jmp end
tenprint:
	cpi count2, 0
	breq print
	subi count2, -'0'
	do_lcd_dataRG count2
	subi count1, -'0'
	do_lcd_dataRG count1
	jmp end
print:
	subi count1, -'0'
	do_lcd_dataRG count1
	jmp end
end:
	rjmp end







