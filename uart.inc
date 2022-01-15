; STC89C52
;-----------------------------------------
;define baudrate const
; (1T:M=1; 12T:M=12)
; /32 if not SMOD
;NOTE: (FOSC/16/BAUDRATE/M) must be greater than 75, (RECOMMEND GREATER THEN 100)

M		EQU	12
FOSC		EQU	11059200
;BAUDRATE	EQU	115200
;BAUDRATE	EQU	57600
BAUDRATE	EQU	19200
;BAUDRATE	EQU	9600
;BAUDRATE	EQU	1200
BAUD		EQU	256 - FOSC/BAUDRATE/16/M

RXB		BIT	P3.0
TXB		BIT	P3.1

AUXR		EQU	8Eh

uart_init:
	mov	PCON,#80h		; double data rate (SMOD=1)
	mov	SCON,#52h		; 8-bit variable baud rate (mode 1)
	mov	TMOD,#20h		; timer1 8-bit auto reload mode
	mov	TL1,#BAUD
	mov	TH1,#BAUD

	setb	TR1			; start timer1
	ret

; recv character in A
uart_recv:
get_char:
	jnb	RI,$
	clr	RI
	mov	A,SBUF
	ret

; send character in A
uart_send:
print_char:
	jnb	TI,$			; wait for current byte to be sent
	clr	TI			; sending something
	mov	SBUF,A			; put byte into transmit buffer
	ret

; nul-terminated string in DPTR
print_string:
	push	ACC
1:
	clr	A
	movc	A,@A+DPTR
	jz	2f
	acall	print_char
	inc	DPTR
	sjmp	1b
2:
	pop	ACC
	ret

hex2asc:
	clr	C
	subb	A,#0AH			; subtract 0AH from A
	jc	2f			; when a carry is present, A is numeric
	add	A,#07H
2:
	add	A,#3AH			; add 30H with A to get ASCII
	acall	print_char
	ret

print_hex:
	push	ACC
	push	ACC
	swap	A
	anl	A,#0FH
	acall	hex2asc
	pop	ACC
	anl	A,#0FH
	acall	hex2asc
	pop	ACC
	ret
