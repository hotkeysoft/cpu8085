.module 	inttest
.title 		Tests Integer Module

.include	'integer.def'

STACK	==	0xFFFF			;SYSTEM STACK

.area	BOOT	(ABS)

.org 	0x0000
	
RST0:
	DI
	LXI	SP,STACK		;INITALIZE STACK
	JMP 	START

.org	0x0038
RST7:	
	HLT
	

;*********************************************************
;* MAIN PROGRAM
;*********************************************************
.area 	_CODE

START:
	JMP	TEST_ATOI

	LXI	H,INT_ACC0
	MVI	M,0xFF
	INX	H
	MVI	M,0x00

	LXI	H,INT_ACC1
	MVI	M,0x01
	INX	H
	MVI	M,0x00

	LXI	H,INT_ACC1
	CALL	INT_DIV
	
TEST_ATOI:

	LXI	H,TESTSTR1
	CALL	INT_ATOI

	LXI	H,TESTSTR2
	CALL	INT_ATOI

	LXI	H,TESTSTR3
	CALL	INT_ATOI

	LXI	H,TESTSTR4
	CALL	INT_ATOI

	LXI	H,TESTSTR5
	CALL	INT_ATOI

	LXI	H,TESTSTR6
	CALL	INT_ATOI

	LXI	H,TESTSTR7
	CALL	INT_ATOI

	LXI	H,TESTSTR8
	CALL	INT_ATOI

	LXI	H,TESTSTR9
	CALL	INT_ATOI

	LXI	H,TESTSTR10
	CALL	INT_ATOI

	LXI	H,TESTSTR11
	CALL	INT_ATOI

	LXI	H,TESTSTR12
	CALL	INT_ATOI

	LXI	H,TESTSTR13
	CALL	INT_ATOI

	LXI	H,TESTSTR14
	CALL	INT_ATOI

	LXI	H,TESTSTR15
	CALL	INT_ATOI

	LXI	H,TESTSTR16
	CALL	INT_ATOI

	LXI	H,TESTSTR17
	CALL	INT_ATOI

	LXI	H,TESTSTR18
	CALL	INT_ATOI

	LXI	H,TESTSTR19
	CALL	INT_ATOI

	LXI	H,TESTSTR20
	CALL	INT_ATOI

	LXI	H,TESTSTR21
	CALL	INT_ATOI


LOOP:
	JMP	LOOP

TESTSTR1:	.asciz	'0'
TESTSTR2:	.asciz	'1'
TESTSTR3:	.asciz	'12'
TESTSTR4:	.asciz	'123'
TESTSTR5:	.asciz	'1234'
TESTSTR6:	.asciz	'12345'
TESTSTR7:	.asciz	'123456'

TESTSTR8:	.asciz	'+0'
TESTSTR9:	.asciz	'+1'
TESTSTR10:	.asciz	'+12'
TESTSTR11:	.asciz	'+123'
TESTSTR12:	.asciz	'+1234'
TESTSTR13:	.asciz	'+12345'
TESTSTR14:	.asciz	'+123456'

TESTSTR15:	.asciz	'-0'
TESTSTR16:	.asciz	'-1'
TESTSTR17:	.asciz	'-12'
TESTSTR18:	.asciz	'-123'
TESTSTR19:	.asciz	'-1234'
TESTSTR20:	.asciz	'-12345'
TESTSTR21:	.asciz	'-123456'

