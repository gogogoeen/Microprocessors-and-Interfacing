;
; lab3.asm
;
; Created: 2019/10/31 上午 07:44:00
; Author : Chuang-Yin Wang
;


; The program gets input from keypad and displays its ascii value on the
; LED bar
.include "m2560def.inc"
.def row = r16 ; current row number
.def col = r17 ; current column number
.def rmask = r18 ; mask for current row during scan
.def cmask = r19 ; mask for current column during scan
.def temp1 = r20
.def temp2 = r21
.def data  = r22
.def temp  = r23
.def del_lo = r24
.def del_hi = r25
.equ PORTFDIR = 0xF0 ; PF7-4: output, PF3-0, input
.equ ROWMASK =0x0F ; for obtaining input from Port F
.equ INITCOLMASK = 0xEF ; scan from the leftmost column,
.equ INITROWMASK = 0x01 ; scan from the top row
.set LCD_RS = 7
.set LCD_RW = 5
.set LCD_E  = 6
.set LCD_FUNC_SET = 0b00110000
.set LCD_N  = 3
.set LCD_DISP_OFF = 0b00001000
.set LCD_DISP_CLR = 0b00000001
.set LCD_ID = 1
.set LCD_ENTRY_SET = 0b00000100
.set LCD_DISP_ON  = 0b00001100
.set LCD_C = 1
.def a = r10
.def b = r11
.def c = r12
.def ten = r5
.def hundred = r6
.def count1 =r7
.def count2 =r3
.def count3 = r9
;r26 r27 r28 are used as well

; General purpose register data stores value to be written to the LCD
; Port C is output and connects to LCD; Port A controls the LCD (Bit LCD_RS for RS and
; bit LCD_RW for RW, LCD_E for E). The character to be displayed is stored in register data
; Assume all labels are pre-defined.
.macro lcd_write_com
	out PORTC, data			; set the data port's value up
	ldi temp, (0<<LCD_RS)|(0<<LCD_RW)
	out PORTA, temp			; RS = 0, RW = 0 for a command write
	nop						; delay to meet timing (Set up time)
	sbi PORTA, LCD_E		; turn on the enable pin
	nop						; delay to meet timing (Enable pulse width)
	nop
	nop
	cbi PORTA, LCD_E		; turn off the enable pin
	nop						; delay to meet timing (Enable cycle time)
	nop
	nop
.endmacro

; comments are same as in previous slide. 
.macro lcd_write_data
	out PORTC, data			; set the data port's value up
	ldi temp, (1 << LCD_RS)|(0<<LCD_RW)
	out PORTA, temp			; RS = 1, RW = 0 for a data write
	nop						; delay to meet timing (Set up time)
	sbi PORTA, LCD_E		; turn on the enable pin
	nop						; delay to meet timing (Enable pulse width)
	nop
	nop
	cbi PORTA, LCD_E		; turn off the enable pin
	nop						; delay to meet timing (Enable cycle time)
	nop
	nop
.endmacro


; comments are same as in the previous slide
.macro lcd_wait_busy
	clr temp
	out DDRC, temp			; Make PORTC be an input port for now
	out PORTC, temp
	ldi temp, 1 << LCD_RW
	out PORTA, temp			; RS = 0, RW = 1 for a command port read
busy_loop:
	nop						; delay to meet set-up time
	sbi PORTA, LCD_E		; turn on the enable pin
	nop						; delay to meet timing (Data delay time)
	nop
	nop
	in temp, PINC			; read value from LCD
	cbi PORTA, LCD_E		; turn off the enable pin
	sbrc temp, 7			; if the busy flag is set(LCD_BF=7)
	rjmp busy_loop			; repeat command read
	clr temp				; else
	out PORTA, temp			; turn off read mode,
	ser temp ;
	out DDRC, temp			; make PORTF an output port again
.endmacro


; The del_hi:del_lo register pair store the loop counts
; each loop generates about 1 us delay
.macro LCDdelay
loop1:
	ldi r26, 0x3
loop2: 
	dec r26
	nop
	brne loop2
	subi del_lo, 1
	sbci del_hi, 0
	brne loop1				; taken branch takes two cycles.
							; one loop iteration time is 16 cycles = ~1.08us
.endmacro




RESET:
	ldi temp1, PORTFDIR		; PF7:4/PF3:0, out/in
	out DDRF, temp1
	ser temp1				; PORTC is output
	out DDRC, temp1
	out DDRA, temp1			; PORTA is output
	clr a
	clr b
	clr c
	ldi r27, 10
	mov ten, r27
	ldi r27, 100
	mov hundred, r27
	clr data
	
	
	ldi del_lo, low(15000)	;delay (>15ms)
	ldi del_hi, high(15000)
	LCDdelay
							; Function set command with N = 1 and F = 0
							; for 2 line display and 5*7 font. The 1st command
	ldi data, LCD_FUNC_SET | (0 << LCD_N)
	lcd_write_com
	ldi del_lo, low(4100)	; delay (>4.1 ms)
	ldi del_hi, high(4100)
	LCDdelay
	lcd_write_com			; 2nd Function set command
							; continued
	ldi del_lo, low(100)	; delay (>100 ns)
	ldi del_hi, high(100)
	LCDdelay
	lcd_write_com			; 3rd Function set command
	lcd_write_com			; Final Function set command
	lcd_wait_busy			; Wait until the LCD is ready
	ldi data, LCD_DISP_OFF
	lcd_write_com			; Turn Display off
	lcd_wait_busy			; Wait until the LCD is ready
	ldi data, LCD_DISP_CLR
	lcd_write_com			; Clear Display
	lcd_wait_busy			; Wait until the LCD is ready
							; Entry set command with I/D = 1 and S = 0
							; Set Entry mode: Increment = yes and Shift = no
	ldi data, LCD_ENTRY_SET | (1 << LCD_ID)
	lcd_write_com
	lcd_wait_busy			; Wait until the LCD is ready
							; Display On command with C = 1 and B = 0
	ldi data, LCD_DISP_ON | (1 << LCD_C)
	lcd_write_com



main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col					; initial column

colloop:
	cpi col, 4
	breq main				; if all keys are scanned, repeat.
	out PORTF, cmask		; otherwise, scan a column
	ldi temp1, 0xFF			; slow down the scan operation.
delay: 
	dec temp1
	brne delay
	in temp1, PINF			; read PORTF
	andi temp1, ROWMASK		; get the keypad output value
	cpi temp1, 0xF			; check if any row is low
	breq nextcol
							; if yes, find which row is low
	ldi rmask, INITROWMASK	; initialize for row check
	clr row ;
	
rowloop:
	cpi row, 4
	breq nextcol			; the row scan is over.
	mov temp2, temp1
	and temp2, rmask		; check un-masked bit
	breq convert			; if bit is clear, the key is pressed
	inc row					; else move to the next row
	lsl rmask
	jmp rowloop
nextcol:					; if row scan is over
	lsl cmask
	inc col					; increase column value
	jmp colloop				; go to the next column 

convert:
	cpi col, 3				; If the pressed key is in col. 3
	breq letters			; we have a letter
							; If the key is not in col. 3 and
	cpi row, 3				; if the key is in row3,
	breq symbols			; we have a symbol or 0
	mov temp1, row			; Otherwise we have a number in 1-9
	lsl temp1
	add temp1, row			;
	add temp1, col			; temp1 = row*3 + col
	subi temp1, (-1)
	;mul b, ten				;
	;cpi r1, 0
	;brne ovr				;if b*10 is overflow
	;mov b, r0
	;add b, temp1			;b=10*b(last time)+templ1
	;brcs ovr				;if b is over flow
	subi temp1, -'0'		; Add the value of character ‘1’
	jmp convert_end			

letters:
	ldi temp1, 'A'
	add temp1, row			; Get the ASCII value for the key
	jmp convert_end

ovr:
	jmp overflow

symbols:
	cpi col, 0				; Check if we have a star
	breq star
	cpi col, 1				; or if we have zero
	breq zero
	ldi temp1, '#'			; if not we have hash
	;mul a, b
	;cpi r1, 0
	;brne ovr
	;mov c, r0
	;jmp result
	jmp convert_end
star:
	ldi temp1, '*'			; Set to star
	mov a, b				;move b to a
	clr b
	jmp convert_end
zero:
	ldi temp1, '0'			; Set to zero
	;mul b, ten				;
	;cpi r1, 0
	;brne ovr
	;mov b, r0
	jmp convert_end

convert_end:
	mov data, temp1			; move the result temp1 to data
	lcd_write_data						

	clr r27
	ldi r28, 10
pressloop:
	subi r27, (-1)
	ldi del_lo, low(999999)	; delay (>100 ns)
	ldi del_hi, high(999999)
	LCDdelay
	cp r27, r28
	brne pressloop


	jmp main				; Restart main loop

overflow:
	ldi data, LCD_DISP_CLR
	lcd_write_com			; Clear Display
	ldi data, 'O'
	lcd_write_data
	ldi data, 'V'
	lcd_write_data
	ldi data, 'E'
	lcd_write_data
	ldi data, 'R'
	lcd_write_data
	ldi data, 'F'
	lcd_write_data
	ldi data, 'L'
	lcd_write_data
	ldi data, 'O'
	lcd_write_data
	ldi data, 'W'
	lcd_write_data	
	jmp end

;result:
;	ldi data, LCD_DISP_CLR
;	lcd_write_com			; Clear Display
;	clr count1
;	clr count2
;	clr count3
;hundredcount:
;	cpi c, 100
;	brlo tencount
;	subi c ,100
;	subi count3, -1
;	rjmp hundredcount

;tencount:
;	cpi c,10
;	brlo onecount
;	subi c, 10
;	subi count2, -1
;	rjmp tencount
;
;onecount:
;	cpi c,1
;	brlo print
;	subi c, 1
;	subi count1, -1
;	rjmp onecount 
;print3:
;	cpi count3, 0
;	breq print2
;	subi count3, -'0'
;	mov data, count3
;	lcd_write_data
;	subi count2, -'0'
;	mov data, count2
;	lcd_write_data
;	subi count1, -'0'
;	mov data, count1
;	lcd_write_data
;	rjmp end

;print2:
;	cpi count2, 0
;	breq print
;	subi count2, -'0'
;	mov data, count2
;	lcd_write_data
;	subi count1, -'0'
;	mov data, count1
;	lcd_write_data
;	rjmp end


;print:
;	subi count1, -'0'
;	mov data, count1
;	lcd_write_data
;	rjmp end
	

end:
	rjmp end

	
	



