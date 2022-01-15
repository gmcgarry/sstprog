; STC89C52
; SST 39SF010 128KBx8 (A16 not connected, pulled low)
;
; $ screen /dev/ttyUSB0 19200
; paste intel hex code into terminal

	ADDRL	EQU	P0
	ADDRH	EQU	P2
	DATA	EQU	P1
	CS	EQU	P3.7
	OE	EQU	P3.6
	WE	EQU	P3.5

	AR0	EQU	0
	AR1	EQU	1
	AR2	EQU	2
	AR7	EQU	7

	.org	0000h			; reset vector
	ajmp	main

	.org	20h
	.include "uart.inc"
	
main:
	clr	PSW
	mov	SP,#7FH			; initialise stack

	mov	ADDRH,#0x00
	mov	ADDRL,#0x00
	mov	DATA,#0xFF
	setb	CS
	setb	WE
	setb	OE

	acall	uart_init

	mov	DPTR,#message
	acall	print_string

loop:
	acall	get_char
;	acall	print_char
;	push	ACC
;	mov	A,#' '
;	acall	print_char
;	pop	ACC
;	acall	print_hex
;	mov	DPTR,#crlf
;	acall	print_string

1:
	cjne	A,#':',2f		; write
	acall	WriteMemory
	sjmp	loop
2:
	cjne	A,#'D',3f		; dump
	acall	DumpMemory
	sjmp	loop
3:
	cjne	A,#'I',4f		; identity
	acall	Identify
	sjmp	loop
4:
	cjne	A,#'E',9f
	acall	ChipErase
	sjmp	loop
9:
	mov	DPTR,#invalid
	acall	print_string
	sjmp	loop

Identify:
	mov	DPTR,#identify
	acall	print_string

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr 	CS
	clr	WE
	mov	DATA,#0xAA
	setb	WE
	setb	CS
	mov	ADDRH,#0x2A
	mov	ADDRL,#0xAA
	clr	CS
	clr	WE
	mov	DATA,#0x55
	setb	WE
	setb	CS
	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr	CS
	clr	WE
	mov	DATA,#0x90
	setb	WE
	setb	CS

	nop
	nop

	mov	DATA,#0xFF
	mov	ADDRH,#0x00
	mov	ADDRL,#0x00
	clr	CS
	clr	OE
	nop
	mov	A,DATA
	setb	OE
	setb	CS
	acall	print_hex
	mov	ADDRL,#0x01
	clr	CS
	clr	OE
	nop
	mov	A,DATA
	setb	OE
	setb	CS
	acall	print_hex

	nop
	nop

	mov	DPTR,#crlf
	acall	print_string

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr 	CS
	clr	WE
	mov	DATA,#0xAA
	setb	WE
	setb	CS
	mov	ADDRH,#0x2A
	mov	ADDRL,#0xAA
	clr	CS
	clr	WE
	mov	DATA,#0x55
	setb	WE
	setb	CS
	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr	CS
	clr	WE
	mov	DATA,#0xF0
	setb	WE
	setb	CS

	mov	DPTR,#done
	acall	print_string

	ret

ChipErase:
	mov	DPTR,#erase
	acall	print_string

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr 	CS
	clr	WE
	mov	DATA,#0xAA
	setb	WE
	setb	CS

	mov	ADDRH,#0x2A
	mov	ADDRL,#0xAA
	clr	CS
	clr	WE
	mov	DATA,#0x55
	setb	WE
	setb	CS

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr	CS
	clr	WE
	mov	DATA,#0x80
	setb	WE
	setb	CS

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr 	CS
	clr	WE
	mov	DATA,#0xAA
	setb	WE
	setb	CS

	mov	ADDRH,#0x2A
	mov	ADDRL,#0xAA
	clr	CS
	clr	WE
	mov	DATA,#0x55
	setb	WE
	setb	CS

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr	CS
	clr	WE
	mov	DATA,#0x10
	setb	WE
	setb	CS

	; wait 100ms (100000 cycles at 11.0592MHz)
	mov	R0,#0x02
	mov	R1,#0xFF
	mov	R2,#0xFF
1:
	djnz	R2,1b
	djnz	R1,1b
	djnz	R0,1b

	mov	DPTR,#done
	acall	print_string

	ret

DumpMemory:
	mov	DPTR,#dump
	acall	print_string

	mov	R6,#0x00
	mov	R7,#0x00
1:
	mov	A,R7
	anl	A,#0x0F
	cjne	A,#0,2f
	mov	DPTR,#crlf
	acall	print_string
	mov	A,R6
	acall	print_hex
	mov	A,R7
	acall	print_hex
	mov	A,#':'
	acall	print_char
2:
	mov	A,#' '
	acall	print_char

	mov	ADDRH,r6
	mov	ADDRL,r7
	mov	DATA,#0xFF

	clr	CS
	clr	OE
	mov	A,DATA
	setb	OE
	setb	CS
	acall	print_hex

	inc	R7
	cjne	R7,#0,1b
	inc	R6
	cjne	R6,#0,1b

	mov	A,#crlf
	acall	print_string

	ret

WriteMemory:
	acall	GetHex		; number of bytes
	jz	9f
	mov	R7,A
	acall	GetHex		; address high
	mov	R6,A
	acall	GetHex		; address low
	mov	R5,A
	acall	GetHex		; type
	jnz	9f

	clr 	CS
2:
	acall	GetHex

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr	WE
	mov	DATA,#0xAA
	setb	WE

	mov	ADDRH,#0x2A
	mov	ADDRL,#0xAA
	clr	WE
	mov	DATA,#0x55
	setb	WE

	mov	ADDRH,#0x55
	mov	ADDRL,#0x55
	clr	WE
	mov	DATA,#0xA0
	setb	WE

	mov	ADDRH,R6
	mov	ADDRL,R5
	clr	WE
	mov	DATA,A
	setb	WE

	inc	R5

	djnz	R7,2b

	setb	CS
9:
	acall	get_char
	cjne	A,#'\r',9b
	
	ret

; R0 points to buffer, returns result in A
DeHex:
	push	AR7
	mov	A,@R0
	inc	R0
	clr	C
	subb	A,#'A'			; subtract 'A' from A
        jnc	2f			; when a carry is present, A is numeric
        add     A,#('A' - '0' - 10)
2:
	add	A,#10
	swap	A
	mov	R7,A
	mov	A,@R0
	inc	R0
	clr	C
	subb	A,#'A'
	jnc	3f
	add	A,#('A' - '0' - 10)
3:
	add	A,#10
	add	A,R7
	pop	AR7
	ret

	BUFFER	EQU	0x20
GetHex:
	acall	get_char
	mov	BUFFER,A
	acall	get_char
	mov	BUFFER+1,A
	mov	R0,#BUFFER
	acall	DeHex
	ret

message:
	.asciz "SST39SF010 Programmer\r\n"
crlf:
	.asciz "\r\n"
dump:
	.asciz "Dump\r\n"
identify:
	.asciz "Identify:\r\n"
erase:
	.asciz "Chip Erase:\r\n"
done:
	.asciz "done\r\n"
invalid:
	.asciz "invalid entry\r\n"

	.end
