.module 	tokenize
.title 		Tokenization of basic statements

.include	'..\common\common.def'
.include	'..\integer\integer.def'
.include	'..\error\error.def'
.include	'..\io\io.def'

.area	_CODE

;*********************************************************
;* TOK_CMP:  	CHECK IF CURRENT STRING MATCHES CURRENT
;* 		TOKEN.  
;*		H-L: PTR IN TOKEN TABLE:
;*		D-E: PTR TO STRING
;*		OUTPUT: CF = 1 IF FOUND
;*		IF NOT FOUND, H-L ADVANCED TO NEXT TOKEN
;*		** B is modified **
TOK_CMP:
	PUSH	D
	
	MVI	B,0				; B COUNTS TOKEN LENGTH
1$:	
	LDAX	D				; ACC = CURRENT CHAR IN STR
	
;	CALL	C_ISALPHA			; CHECK IF LETTER
;	JNC	NOTLETTER
	
;	ANI	223				; IF SO, CONVERT TO UPPERCASE
	
2$:
	CMP	M				; COMPARE WITH CURRENT TOKEN LETTER
	JNZ	3$				; EXIT LOOP IF DIFFERENT
	
	INX	H				; INCREMENT TOKEN TABLE PTR
	INX	D				; INCREMENT STR PTR
	INR	B				; INCREMENT LENGTH COUNTER
	
	JMP	1$				; LOOP
	
3$:
	MOV	A,M				; CHECK IF DIFFERENT CHAR IS 
	ORA	A				; END OF TOKEN
	JM	5$				; BY CHECKING UPPER BIT FOR '1'
	JZ	5$				; OR END OF TABLE

4$:						; ADVANCE TO NEXT TOKEN
	INX	H
	MOV	A,M				; CHECK FOR BEGIN OF NEXT TOKEN
	ORA	A				; (UPPER BIT == 1)
	JZ	6$				; FOUND END OF TABLE
	JP	4$				; LOOP UNTIL FOUND

	JMP	6$
	
5$:	STC					; SET CARRY TO INDICATE FOUND
	MOV	A,B				; TOKEN LENGTH
	STA	TOK_CURRTOKENLEN		; STORE IN VAR

6$:
	POP	D	
	RET


;*********************************************************
;* TOK_FINDTOKENID:  	FINDS TOKEN ID FROM STRING AT 
;* 			[H-L].  SETS TOK_CURRTOKEN
;*			TO ID IF FOUND, ELSE 0
TOK_FINDTOKENID::
	PUSH	B
	PUSH	D
	PUSH	H
	
	XCHG					; STRING IN D-E

	LXI	H,K_TABLE			; HL POINTS TO TOKEN TABLE
	
1$:
	MOV	A,M				; READ ID FROM TOKEN TABLE
	STA	TOK_CURRTOKEN			; STORE IN CURRTOKEN
	
	ORA	A				; CHECK IF 0 (END OF TABLE)
	JZ 	2$

	INX	H				; FIRST CHAR OF TOKEN STRING

	CALL	TOK_CMP				; COMPARE WITH CURRENT STRING
	
	JC	2$
	
	JMP	1$
	
2$:
	POP	H
	POP	D
	POP	B
	RET

;*********************************************************
;* TOK_FINDTOKENSTR:  	FROM STRING ID IN ACC,
;*			SETS H-L TO POINT TO CORRESPONDING
;*			STRING (OR 0x0000 IF NOT FOUND)
TOK_FINDTOKENSTR::
	PUSH	B
	
	MOV	B,A				; ID TO FIND IN B	

	
	LXI	H,K_TABLE			; HL POINTS TO TOKEN TABLE

1$:
	MOV	A,M				; CURRENT ID IN A
	
	CMP	B				; CHECK IF FOUND TOKEN
	JZ	3$
	
	ORA	A				; CHECK IF END OF TABLE
	JZ	2$
	
	INX	H				; ADVANCE IN TABLE
	
	JMP	1$

2$:
	LXI	H,0				; NOT FOUND, HL = 0
	JMP	4$

3$:
	INX	H				; FOUND, STR IS AT PTR+1

4$:
	POP	B

	RET

;*********************************************************
;* TOK_TOKENIZE1:  TOKENIZE, PASS 1: CONVERTS KEYWORDS
;*		   TO TOKENS, IGNORE VARIABLES, 
;*		   CONSTANTS & DELIMITERS.  TOKENIZATION
;*		   IS DONE IN PLACE, IN THE INPUT STRING
;*		   (PTR IN H-L)
TOK_TOKENIZE1::
	PUSH	B
	PUSH	H

	MVI	A,0
	STA	TOK_LASTTOKEN			; LAST TOKEN = 0
	
1$:
	MOV	A,M				; CURRENT CHAR
	
	ORA	A				; CHECK IF END OF STRING
	JZ	11$

	; CHECK FOR WHITESPACE
	CPI	' 				
	JZ	4$

	; CHECK FOR DELIMITER
	CPI	'(
	JZ	9$
	CPI	')
	JZ	9$
	CPI	':
	JZ	9$
	CPI	';
	JZ	9$
	CPI	',
	JZ	9$
	
	; CHECK FOR BEGINNING OF STRING
	CPI	'"		
	JZ	5$

	; CHECK FOR MINUS SIGN.  PARTLY HANDLED HERE, 
	; NON OBVIOUS CASES HANDLED IN TOKENIZE2
	CPI	'-
	JZ	7$
	
	; CHECK FOR TOKEN
	CALL 	TOK_FINDTOKENID
	
	LDA	TOK_CURRTOKEN			; CURRENT TOKEN IN ACC
	
	ORA	A				; TOKEN == 0 -> NOT FOUND
	JZ	9$
	
	; TOKEN WAS FOUND, REPLACE IN STRING (PAD WITH 0xFF)
	STA	TOK_LASTTOKEN			; LAST TOKEN = CURR TOKEN
	
	MOV	M,A				; PUT TOKEN IN STRING
	INX	H				; HL++
	
	LDA	TOK_CURRTOKENLEN		; LENGTH OF TOKEN
	MOV	B,A				; IN B
	
	MVI	A,0xFF				; FILL WITH 0xFF
	
2$:	
	DCR	B				; LEN-1 (FIRST CHAR IS TOKEN)
	
	JZ	3$				; END OF PAD, GOTO MAIN LOOP
	
	MOV	M,A				; PAD WITH 0xFF
	INX	H				; HL++
	JMP	2$				; LOOP
	
3$:
	LDA	TOK_CURRTOKEN			; CHECK IF TOKEN IS 'REM'
	CPI	K_REM				; IF SO, DO NOT TOUCH REST
	JZ	11$				; OF THE LINE 
	
	JMP	1$

4$:						; WHITESPACE (IGNORED)
	INX	H				; HL++
	JMP	1$				; LOOP

5$:
	INX	H
	MOV	A,M				; NEXT CHAR
	
	ORA	A
	JZ	6$				; EXIT LOOP IF NULL OR '"'
	CPI	'"
	JNZ	5$				; LOOP
6$:
	ORA	A				; CHECK IF EXIT BECAUSE OF NULL
	JZ	ERR_TOK_NOENDSTR		; UNTERMINATED STRING CONST
	
	JMP	9$

7$:
	LDA	TOK_LASTTOKEN			; CHECK LAST TOKEN
	
	CPI	'(
	JZ	8$
	CPI	':
	JZ	8$
	CPI	';
	JZ	8$
	CPI	',
	JZ	8$
	
	ANI	0xE0				; CHECK IF ARITHMETIC OP
	CPI	0x80
	JZ	8$
	
	; WE CAN'T DECIDE FOR SURE, SO LEAVE AS IT IS
	JMP	9$	

8$:	; THE '-' IS AN UNARY OP
	MVI	A,K_NEGATE			; REPLACE CHAR IN STRING
	MOV	M,A
	JMP	9$

9$:
	STA	TOK_LASTTOKEN			; LAST TOKEN = DELIMITER
	INX	H				; HL++
	JMP	1$				; LOOP

11$:
	POP	H
	POP	B

	RET
	
;*********************************************************
;* TOK_TOKENIZE2:  TOKENIZE, PASS 2: ENCODES VARIABLES
;*		   & CONSTANTS.  
;*		   INPUT STRING IN (D-E)
;*		   OUTPUT STRING IN (H-L)
TOK_TOKENIZE2::

	PUSH	D
	PUSH	H

	MVI	A,0
	STA	TOK_LASTTOKEN			; LAST TOKEN = 0

1$:
	LDAX	D				; CURRIN IN ACC
	
	ORA	A				; CHECK IF NULL
	JZ	14$				; IF SO, EXIT

	CPI	0xFF				; SKIP 0xFF
	JZ	2$
	
	CPI	0x80				; ACC >= 0x80 ->
	JAE	3$				; FOUND TOKEN
	
	; STRING CONSTANT
	CPI	'"	
	JZ	5$
	
	CPI	'-
	JZ	8$
	
	CALL	C_ISDIGIT			; CHECK FOR NUMBER
	JC	10$
	
	CALL	C_ISALPHA			; CHECK FOR LETTER
	JC	11$
	
	; CHECK FOR DELIMITERS
	CPI	'(
	JZ	12$
	
	CPI	')
	JZ	12$
	
	CPI	';
	JZ	12$
	
	CPI	',
	JZ	12$
	
	CPI	':
	JZ	12$

	; CHECK FOR WHITESPACE
	CPI	' 		
	JZ	13$

; INVALID CHAR
	JMP	ERR_TOK_INVALIDCHAR	

2$:
	INX	D				; INSTR++	
	JMP	1$				; LOOP

3$:
	MOV	M,A				; COPY CHAR TO OUTSTR
	STA	TOK_LASTTOKEN			; SET LASTTOKEN
	INX	D				; INSTR++
	INX	H				; OUTSTR++
	
	CPI	K_REM				; CHECK IF REM STATEMENT
	JNZ	1$				; IF NOT, LOOP
	
	;REM STATEMENT
	INX	D				; INSTR += 2 (SKIP 'E' 'M')
	INX	D

4$:
	LDAX	D				; CURRIN IN ACC
	ORA	A				; CHECK IF END OF STR
	JZ	14$				; IF SO, EXIT
	
	MOV	M,A				; COPY CHAR TO OUTSTR
	
	INX	D				; INSTR++
	INX	H				; OUTSTR++
	JMP	4$				; LOOP

5$:
	MVI	A,SID_CSTR
	MOV	M,A				; STRING ID
	STA	TOK_LASTTOKEN			; SAVE AS LAST TOKEN

	INX	D				; INSTR++
	INX	H				; OUTSTR++
	
	PUSH	H				; KEEP THIS PLACE
	MVI	M,0				; LENGTH (WILL GO BACK LATER)
	INX	H				; OUTSTR++
	
	LXI	B,0				; LENGTH COUNTER
6$:
	LDAX	D				; CURRIN IN ACC
	CPI	'"				; END OF STRING?
	JZ	7$

	MOV	M,A				; COPY CHAR TO OUTSTR
	
	INX	D				; INSTR++
	INX	H				; OUTSTR++
	INR	C				; LENGTH++
	JMP	6$				; LOOP
	
7$:
	INX	D				; SKIP TRAILING '"'
	
	POP	H				; GO BACK TO BEGINNING OF STR
	MOV	M,C				; SAVE LENGTH
	
	DAD	B				; ADD LEN OF STRING TO OUTSTR
	INX	H				; OUTSTR++
			
	JMP	1$				; LOOP
	
8$:
	LDA	TOK_LASTTOKEN			; GET LASTTOKEN IN ACC
	
	; CHECK FOR PRECEDING CONST OR VARIABLE
	CPI	SID_CINT
	JZ	9$
	CPI	SID_CSTR
	JZ	9$
	CPI	SID_VAR
	JZ	9$

	; OTHER CASES: UNARY
	MVI	A,K_NEGATE			; '-' IS UNARY
	JMP	12$

9$:
	MVI	A,K_SUBSTRACT			; '-' IS BINARY
	JMP	12$


10$:	XCHG					; SWAP HL<->DE
	CALL	INT_ATOI			; EXTRACT NUMBER
	XCHG					; SWAP HL<->DE
	
	MVI	A,SID_CINT			; CONST INT
	STA	TOK_LASTTOKEN			; STORE AS LAST TOKEN
	MOV	M,A				; STORE IN OUT STRING
	INX	H				; OUTSTR++
	
	LDA	INT_ACC0			; LO BYTE
	MOV	M,A				; STORE IN OUTSTR
	INX	H				; OUTSTR++
	
	LDA	INT_ACC0+1			; HI BYTE
	MOV	M,A				; STORE IN OUTSTR
	INX	H				; OUTSTR++
	
	JMP	1$

11$:
	XCHG					; SWAP HL<->DE
	CALL	C_NAME2TAG			; EXTRACT VARIABLE NAME
	XCHG					; SWAP HL<->DE

	MVI	A,SID_VAR			; CONST INT
	STA	TOK_LASTTOKEN			; STORE AS LAST TOKEN
	MOV	M,A				; STORE IN OUT STRING
	INX	H				; OUTSTR++

	MOV	M,B				; LO BYTE OF VAR TAG
	INX	H				; OUTSTR++
	
	MOV	M,C				; HI BYTE OF VAR TAG
	INX	H

	JMP	1$

12$:
	STA	TOK_LASTTOKEN			; SET LASTTOKEN
13$:
	MOV	M,A				; COPY CHAR TO OUTSTR
	INX	D				; INSTR++
	INX	H				; OUTSTR++
	JMP	1$				; LOOP
	
14$:
	MOV	M,A				; WRITE NULL CHAR IN OUTSTR	

	POP	H
	POP	D
	
	RET

;*********************************************************
;* TOK_UNTOKENIZE: FROM A TOKENIZED LINE (PTR IN HL), 
;*		   OUTPUT TEXT VERSION TO CONSOLE
TOK_UNTOKENIZE::
	
LOOP:
	MOV	A,M				; CURRENT CHAR IN ACC
	
	CPI	0				; CHECK FOR END OF STRING
	JZ	END
	
	CPI	SID_CINT			; INT?
	JZ	INT
	
	CPI	SID_CSTR
	JZ	STR
	
	CPI	SID_VAR
	JZ	VAR
	
	CPI	0x80
	JAE	TOKEN
	
	CALL	IO_PUTC				; MISC CHAR 
	
	INX	H				; NEXT CHAR
	JMP	LOOP				; LOOP
	
INT:
	INX	H				; HL++
	
	MOV	E,M				; READ INT IN DE (LO)
	INX	H				; HL++
	MOV	D,M				; (HI)
	INX	H				; HL++
	
	XCHG					; SWAP HL<->DE
	
	SHLD	INT_ACC0			; PUT IN INT_ACC0
	CALL	INT_ITOA			; CONVERT TO STRING
	CALL	IO_PUTS				; PRINT IT

	XCHG					; GET BACK PTR
	JMP	LOOP				; LOOP

STR:

	INX	H				; NEXT CHAR
	
	MOV	B,M				; LENGTH OF STRING IN B
	INX	H
	
	MVI	A,'"				; PUT QUOTES AROUND STRING
	CALL	IO_PUTC
	
	CALL	IO_PUTSN			; PRINT STRING

	MVI	A,'"
	CALL	IO_PUTC
	
	JMP	LOOP				; LOOP

VAR:
	INX	H
	
	MOV	B,M				; READ TAG
	INX	H				; IN BC
	MOV	C,M
	INX	H
	
	XCHG					; KEEP CURRPOS IN DE
	
	LXI	H,TOK_TEMPSTR			; DEST FOR STRING NAME
	CALL	C_TAG2NAME			; CONVERT TAG TO STRING
	CALL	IO_PUTS				; PRINT IT
	
	XCHG
	JMP	LOOP				; LOOP

TOKEN:
	XCHG					; SWAP HL<->DE
	CALL 	TOK_FINDTOKENSTR		; FIND TEXT EQUIVALENT
	CALL	IO_PUTS				; PRINT STRING

	XCHG					; SWAP HL<->DE

	INX	H				; NEXT CHAR
	JMP	LOOP				; LOOP

END:
	RET

;*********************************************************
;* RAM VARIABLES
;*********************************************************

.area	DATA	(REL,CON)

TOK_CURRTOKEN::		.ds	1		; CURRENT TOKEN ID
TOK_CURRTOKENLEN::	.ds	1		; CURRENT TOKEN LENGTH

TOK_LASTTOKEN:		.ds	1		; USED BY TOKENIZE1&2

TOK_TEMPSTR:		.ds	4		; USED BY UNTOKENIZE
