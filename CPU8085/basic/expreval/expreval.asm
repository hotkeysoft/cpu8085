;*********************************************************
;* MODULE:	EXPREVAL
;* 
;* DESCRIPTION:	EVALUATES EXPRESSIONS, EXECUTES FUNCTIONS
;*

.module 	expreval
.title 		Expression evaluation

.include	'..\common\common.def'
.include	'..\variables\variable.def'
.include	'..\integer\integer.def'
.include	'..\io\io.def'
.include	'..\error\error.def'
.include	'..\program\program.def'
.include	'..\strings\strings.def'
.include	'evaluate.def'

.area	_CODE

EXP_STACKSIZE 	= 5*16
EXP_STACKHI	= EXP_STACKLO + EXP_STACKSIZE

;*********************************************************
;* EXP_INIT:  INITIALIZES MODULE
EXP_INIT::
	LXI	H,EXP_STACKLO
	SHLD	EXP_STACKCURR			; EMPTIES STACK		

	RET


;*********************************************************
;* EXP_EXPREVAL:  EXECUTES TOKENIZED EXPRESSION AT [H-L]
;*		  IN: B = INIF, C = EXECUTE
EXP_EXPREVAL::

1$:
	MOV	A,H				; CHECK IF HL IS INVALID
	ORA	L
	JZ	ERR_UNKNOWN
	
	CALL	EXP_SKIPWHITESPACE2		; SKIP SPACES AND ':'

	MOV	A,M				; READ CURR CHAR
	ORA	A
	JZ	101$				; EXIT WITH CF = 0
	
	; IDENTIFY CURRENT FUNCTION	
	CPI	K_LIST
	JZ	2$
	
	CPI	K_END
	JZ	3$

	CPI	K_NEW
	JZ	4$

	CPI	K_PRINT
	JZ	5$
	
	CPI	K_LET
	JZ	6$
	
	CPI	SID_VAR
	JZ	6$

	CPI	K_CLR
	JZ	7$
	
	CPI	K_REM
	JZ	101$
	
	CPI	K_IF
	JZ	8$

	CPI	K_ELSE
	JZ	9$

	CPI	K_RUN
	JZ	10$

	CPI	K_GOTO
	JZ	11$

	CPI	K_GOSUB
	JZ	12$

	CPI	K_RETURN
	JZ	13$

	CPI	K_CLS
	JZ	14$
	
	CPI	K_GOTOXY
	JZ	15$

	CPI	K_FOR
	JZ	16$

	CPI	K_NEXT
	JZ	17$

	CPI	K_INPUT
	JZ	18$

	CPI	K_POKE
	JZ	19$

	CPI	K_SLEEP
	JZ	20$

	CPI	K_BEEP
	JZ	21$

	CPI	K_COLOR
	JZ	22$

.if DEBUG
	CPI	K_DUMPVAR
	JZ	90$

	CPI	K_DUMPSTR
	JZ	92$
.endif	
	
	JMP	ERR_SYNTAX
	
2$:	; LIST
	CALL	EXP_DO_LIST
	JMP	100$

3$:	; END
	CALL	EXP_DO_END
	JC	101$
	JMP	100$

4$:	; NEW
	CALL	EXP_DO_NEW
	JMP	100$

5$:	; PRINT
	CALL	EXP_DO_PRINT
	JMP	100$

6$:	; LET
	CALL	EXP_DO_LET
	JMP	100$

7$:	; CLR
	CALL	EXP_DO_CLR
	JMP	100$

8$:	; IF
	CALL	EXP_DO_IF
	JMP	101$				; EXIT

9$:	; ELSE
	CALL	EXP_DO_ELSE
	JMP	101$				; EXIT

10$:	; RUN
	CALL	EXP_DO_RUN
	JMP	100$

11$:	; GOTO
	CALL	EXP_DO_GOTO
	JC	101$				; EXIT
	JMP	100$

12$:	; GOSUB
	CALL	EXP_DO_GOSUB
	JC	101$				; EXIT
	JMP	100$

13$:	; RETURN
	CALL	EXP_DO_RETURN
	JC	101$				; EXIT
	JMP	100$

14$:	; CLS
	CALL	EXP_DO_CLS
	JMP	100$

15$:	; GOTOXY
	CALL	EXP_DO_GOTOXY
	JMP	100$

16$:	; FOR
	CALL	EXP_DO_FOR
	JMP	100$
	
17$:	; NEXT
	CALL	EXP_DO_NEXT
	JC	101$				; EXIT
	JMP	100$
	
18$:	; INPUT
	CALL	EXP_DO_INPUT
	JMP	100$

19$:	; POKE
	CALL	EXP_DO_POKE
	JMP	100$

20$:	; SLEEP
	CALL	EXP_DO_SLEEP
	JMP	100$

21$:	; BEEP
	CALL	EXP_DO_BEEP
	JMP	100$

22$:	; COLOR
	CALL	EXP_DO_COLOR
	JMP	100$

.if DEBUG
90$:	; DUMP VARIABLES
	INX	H
	CALL	VAR_DUMPVARS
	JMP	100$
	
92$:	; DUMP STRINGS
	INX	H
	CALL	STR_DUMPSTRINGS
	JMP	100$
.endif	
	
100$:	
	CALL	EXP_SKIPWHITESPACE
	
	MOV	A,M				; READ CURR CHAR
	CPI	':				; LOOP IF ':' OR 'ELSE'
	JZ	1$
	CPI	K_ELSE
	JZ	1$
	CPI	0
	JZ	1$
	
	JMP	ERR_SYNTAX

101$:	
	RET
	

;*********************************************************
;* EXP_DO_LIST:  EXECUTE LIST
;*		 IN: C = EXECUTE
EXP_DO_LIST:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	RZ

	CALL	PRG_LIST
	RET

;*********************************************************
;* EXP_DO_END: 	EXECUTE END
;*		IN: C = EXECUTE
;*		OUT: CF = 1 IF MUST EXIT
EXP_DO_END:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	JZ	1$

	CALL	PRG_END
	STC
	RET

1$:
	ORA	A
	RET

;*********************************************************
;* EXP_DO_NEW: 	EXECUTE NEW
;*		IN: C = EXECUTE
EXP_DO_NEW:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	RZ

	CALL	PRG_NEW
	RET

;*********************************************************
;* EXP_DO_CLS: 	EXECUTE CLS
;*		IN: C = EXECUTE
EXP_DO_CLS:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	RZ

	CALL	IO_CLS
	RET

;*********************************************************
;* EXP_DO_GOTOXY: 	EXECUTE GOTOXY
;*			IN: C = EXECUTE
EXP_DO_GOTOXY:
	PUSH	D
	
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ FIRST PARAM (X)
	
	CALL	EXP_SKIPWHITESPACE
	
	MOV	A,M			; CHECK FOR ','
	CPI	',
	JNZ	ERR_SYNTAX
	INX	H
		
	CALL	EXP_L0			; READ SECOND PARAM (Y)

	PUSH	H
	CALL	EVAL_BINARYOP		; GET PARAMETERS IN VAR_TEMP1&2
	
	LDA	VAR_TEMP1		; CHECK TYPE OF PARAM 1
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT
	
	LDA	VAR_TEMP2		; CHECK TYPE OF PARAM 2
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ 	100$

	; VALIDATION OF VALUES	
	LHLD	VAR_TEMP1+1		; READ PARAM1 IN HL (Y)
	MVI	A,0
	ORA	H			; HI BYTE OF Y
	JNZ	ERR_ILLEGAL		; CHECK 0..255
	ORA	L
	JZ	ERR_ILLEGAL		; CHECK >0
	CPI	26
	JAE	ERR_ILLEGAL		; 1..25
	MOV	E,L			; Y VALUE IN E

	LHLD	VAR_TEMP2+1		; READ PARAM2 IN HL (X)
	MVI	A,0
	ORA	H			; HI BYTE OF X
	JNZ	ERR_ILLEGAL		; CHECK 0..255
	ORA	L
	JZ	ERR_ILLEGAL		; CHECK >0
	CPI	81
	JAE	ERR_ILLEGAL		; 1..80
	MOV	D,L			; X VALUE IN D
	
	XCHG				; SWAP HL<->DE	
	
	CALL	IO_GOTOXY		; DO IT
	
100$:
	POP	H
	POP	D
	RET

;*********************************************************
;* EXP_DO_PRINT:EXECUTE PRINT
;*		IN: C = EXECUTE
EXP_DO_PRINT:
	INX	H			; SKIP KEYWORD

	MVI	A,TRUE
	STA	EXP_INSNEWLINE
	
1$:
	CALL	EXP_SKIPWHITESPACE

	MOV	A,M			; READ CURRENT CHAR
	
	; CHECK EXIT CONDITIONS
	CPI	0			; END OF STRING
	JZ	100$
	CPI	':			; SEPARATOR
	JZ	100$
	CPI	K_ELSE			; ELSE KEYWORD
	JZ	100$
	
	MVI	A,TRUE
	STA	EXP_INSNEWLINE
	
	CALL	EXP_L0			; READ EXPRESSION
	
	PUSH	H
	CALL	EVAL_UNARYOP		; EXTRACT RESULT IN VAR_TEMP1
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	TRUE
	JNZ	4$
	
	LDA	VAR_TEMP1		; READ TYPE IN ACC
	
	CPI	SID_CINT		; CHECK FOR INT
	JZ	2$
	
	CPI	SID_CSTR		; CHECK FOR STRING
	JZ	3$
	
	JMP	ERR_UNKNOWN
	
2$:
	LHLD	VAR_TEMP1+1		; READ VALUE IN HL
	SHLD	INT_ACC0		; STORE IN INT_ACC0
	
	CALL	INT_ITOA		; CONVERT TO STRING
	CALL	IO_PUTS			; PRINT VALUE
	JMP	4$
	
3$:
	LDA	VAR_TEMP1+1		; SIZE OF STR IN ACC
	MOV	B,A			; COPY TO B
	
	LHLD	VAR_TEMP1+2		; STR PTR IN HL
	CALL	IO_PUTSN		; PRINT THE STRING
	
	JMP	4$
	
4$:
	POP	H			; RESTORE HL

	MOV	A,M			; READ CURRENT CHAR
	CPI	',
	JZ	5$
	CPI	';
	JZ	6$
	CPI	':
	JZ	100$
	CPI	0
	JZ	100$
	CPI	K_ELSE
	JZ	100$
	
	JMP	ERR_SYNTAX
	
5$:	;	',' SEPARATOR
	INX	H			; SKIP ','
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	TRUE
	JNZ	1$			; LOOP 
	
	MVI	A,9			; TAB
	CALL	IO_PUTC			; PRINT IT

	MVI	A,FALSE
	STA	EXP_INSNEWLINE		; DO NOT INSERT LINE AT THE END

	JMP	1$			; LOOP
	
6$:	;	';' SEPARATOR
	INX	H			; SKIP ';'
	MVI	A,FALSE
	STA	EXP_INSNEWLINE		; DO NOT INSERT LINE AT THE END
	JMP	1$

100$:
	LDA	EXP_INSNEWLINE		; CHECK IF WE HAVE TO INSERT NEW LINE
	CPI	TRUE
	JNZ 	101$
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	TRUE
	JNZ	101$
	
	CALL	IO_PUTCR		; INSERT NEW LINE	
101$:
	RET

;*********************************************************
;* EXP_DO_LET:	EXECUTE VARIABLE ASSIGNATION
;*		IN: C = EXECUTE
EXP_DO_LET:
	PUSH	B
	PUSH	D
	
	CPI	K_LET			; CHECK FOR LET KEYWORD
	JNZ	1$
	
	INX	H			; SKIP 'LET' KEYWORD
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
1$:	
	MOV	A,M			; READ CURR CHAR
	CPI	SID_VAR			; MAKE SURE IT'S A VARIABLE
	JNZ	ERR_SYNTAX
	
	INX	H			; SKIP VARIABLE ID
	
	
	MOV	D,C			; COPY 'EXECUTE' VAR TO D

	
	MOV	B,M			; READ VARIABLE NAME
	INX	H			; IN BC
	MOV	C,M			
	INX	H
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	MOV	A,M			; READ CURR CHAR
	CPI	K_EQUAL			; MUST BE '='
	JNZ	ERR_SYNTAX		
	
	INX	H			; SKIP '='
	
	CALL	EXP_L0			; READ EXPRESSION

	PUSH	H
	CALL	EVAL_UNARYOP		; EXTRACT RESULT IN VAR_TEMP1
	
	MOV	A,D			; CHECK EXECUTE FLAG
	CPI	TRUE
	JNZ	2$
	
	LXI	H,VAR_TEMP1		; SET VARIABLE
	CALL	VAR_SET
	
2$:
	POP	H
	POP	D
	POP	B
	RET

;*********************************************************
;* EXP_DO_CLR: 	EXECUTE CLR
;*		IN: C = EXECUTE
EXP_DO_CLR:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	RZ

	CALL	PRG_CLR

	RET

;*********************************************************
;* EXP_DO_IF: 	EXECUTE IF
;*		IN: B = INIF
;*		IN: C = EXECUTE
EXP_DO_IF:
	MOV	A,B			; NESTED IF ARE NOT ALLOWED
	CPI	TRUE
	JZ	ERR_SYNTAX

	PUSH	B
	
	INX	H			; SKIP KEYWORD

	CALL	EXP_L0			; READ EXPRESSION
	
	PUSH	H
	CALL	EVAL_UNARYOP		; EXTRACT RESULT IN VAR_TEMP1

	LDA	VAR_TEMP1		; READ TYPE OF VARIABLE IN ACC
	CPI	SID_CINT		; MUST EVALUATE TO INT
	JNZ	ERR_TYPEMISMATCH

	MVI	B,TRUE			; INIF = TRUE	
	MVI	C,TRUE			; SET RESULT = TRUE
	
	LHLD	VAR_TEMP1+1		; CHECK RESULT OF EVALUATION
	MVI	A,0
	CMP	H			; HI BYTE
	JNZ	1$
	
	CMP	L			; LO BYTE
	JNZ	1$

	MVI	C,FALSE			; CHANGE RESULT TO FALSE
	
1$:
	; RESULT IN C (TRUE/FALSE)
	POP	H			; GET BACK HL
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	MOV	A,M			; READ CURR CHAR
	CPI	K_THEN			; MUST BE THEN OR GOTO
	JZ	2$
	CPI	K_GOTO
	JZ	4$
	
	JMP	ERR_SYNTAX
	
2$:	; THEN
	INX	H			; SKIP KEYWORD
	CALL	EXP_EXPREVAL		; EVALUATE EXPRESSION
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	MOV	A,M			; CHECK FOR ELSE
	CPI	K_ELSE
	JNZ	3$
	
	; ELSE
	INX	H			; SKIP KEYWORD
	
	MOV	A,C			; EXECUTE = !EXECUTE
	CMA
	MOV	C,A
	MVI	B,TRUE	

	
	CALL	EXP_EXPREVAL		; EVALUATE EXPRESSION
	
3$:
	POP	B
	RET

4$:
	CALL	EXP_EXPREVAL		; EVALUATE EXPRESSION
	POP	B
	RET

;*********************************************************
;* EXP_DO_ELSE:	EXECUTE ELSE
;*		IN: B = INIF
EXP_DO_ELSE:
	MOV	A,B			; CHECK FOR ELSE WITHOUT IF
	CPI	FALSE
	JZ	ERR_ELSEWITHOUTIF
	
	RET

;*********************************************************
;* EXP_DO_RUN:	EXECUTE RUN
;*		IN: C = EXECUTE
EXP_DO_RUN:
	PUSH	D
	MOV	E,C			; COPY EXECUTE TO E
	
	INX	H			; SKIP KEYWORD

	CALL	EXP_L0			; READ EXPRESSION (LINE NUMBER)
	
	LXI	B,-1			; LOAD -1 IN BC
	
	CALL	EXP_ISSTACKEMPTY	; CHECK IF OPTIONAL LINE NO IS HERE
	JC	1$

	PUSH	H
	
	CALL	EVAL_UNARYOP
	
	LDA	VAR_TEMP1		; CHECK TYPE
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT
	
	LDA	VAR_TEMP1+1		; PUT LINE NO IN BC
	MOV	C,A
	LDA	VAR_TEMP1+2
	MOV	B,A
	ORA	A
	JM	ERR_ILLEGAL		; NUMBER MUST BE POSITIVE
	
	POP	H
1$:

	MOV	A,E
	CPI	FALSE			; CHECK EXECUTE FLAG
	JZ	100$

	PUSH	H			; KEEP CURRENT POS
	CALL	PRG_RUN			; RUN PROGRAM
	POP	H			; RESTORE POS
	
100$:	
	POP	D
	RET

;*********************************************************
;* EXP_DO_RETURN:	EXECUTE RETURN
;*			IN: C = EXECUTE
;*			OUT: CF = 1 IF MUST EXIT
EXP_DO_RETURN:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	JZ	1$

	CALL	PRG_RETURN		; EXECUTE RETURN

	STC
	RET
		
1$:
	ORA	A
	RET

;*********************************************************
;* EXP_DO_FOR:		EXECUTE FOR
;*			IN: B = INIF
;*			IN: C = EXECUTE
EXP_DO_FOR:
	PUSH	B
	PUSH	D
	
	INX	H			; SKIP KEYWORD
	
	MVI	A,SID_FOR		; PREPARE DATA TO PUSH
	STA	EXP_STACKTEMP
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	; READ VARIABLE NAME	
	MOV	A,M			; READ CURRENT CHAR
	CPI	SID_VAR			; MUST BE VARIABLE
	JNZ	ERR_SYNTAX
	
	; COPY VARIABLE NAME IN DE
	INX	H
	MOV	D,M			; TAG[0]
	INX	H
	MOV	E,M			; TAG[1]
	INX	H
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	; LOOK FOR '='
	MOV	A,M			; READ CURRENT CHAR
	CPI	K_EQUAL			; MUST BE EQUAL
	JNZ	ERR_SYNTAX
	
	INX	H			; SKIP '=' SYMBOL
	
	CALL	EXP_L0			; READ EXPRESSION (BEGIN VALUE)
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	; LOOK FOR 'TO'
	MOV	A,M			; READ CURRENT CHAR
	CPI	K_TO			; MUST BE 'TO'
	JNZ	ERR_SYNTAX
	
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ EXPRESSION (END VALUE)
	
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	; CHECK FOR OPTIONAL 'STEP'
	MOV	A,M			; READ CURRENT CHAR	
	CPI	K_STEP
	JNZ	1$
	
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ EXPRESSION (STEP VALUE)
	JMP	2$
	
1$:	; NO 'STEP' VALUE - ASSUME 1
	PUSH	H
	
	MVI	A,SID_CINT		; FLAG AS INT
	STA	VAR_TEMP1
	
	LXI	H,1
	SHLD	VAR_TEMP1+1

	LXI	H,VAR_TEMP1		; PUSH 1 ON STACK
	CALL	EXP_PUSH
	
	POP	H

2$:
	PUSH	H

	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	100$
	
	MOV	A,B			; KEEP INIF IN ACC
	
	MOV	B,D			; COPY VAR ID TO BC
	MOV	C,E
	
	MOV	D,A			; D = INIF

	; GET BACK VALUES
	
	; STEP VALUE
	CALL	EVAL_UNARYOP

	LDA	VAR_TEMP1	
	CPI	SID_CINT		; MUST BE INT
	JNZ	ERR_TYPEMISMATCH
	
	LDA	VAR_TEMP1+1
	STA	EXP_STACKTEMP+3
	LDA	VAR_TEMP1+2
	STA	EXP_STACKTEMP+4

	; END VALUE
	CALL	EVAL_UNARYOP
	
	LDA	VAR_TEMP1
	CPI	SID_CINT		; MUST BE INT
	JNZ	ERR_TYPEMISMATCH

	LDA	VAR_TEMP1+1	
	STA	EXP_STACKTEMP+1
	LDA	VAR_TEMP1+2
	STA	EXP_STACKTEMP+2
	
	; BEGIN VALUE
	CALL	EVAL_UNARYOP

	LXI	H,VAR_TEMP1	
	CALL	VAR_SET			; SET VARIABLE = BEGIN VALUE

	LXI	H,EXP_STACKTEMP		; PUSH END/STEP VALUES ON STACK
	CALL	EXP_PUSH
	
	POP	H
	
	CALL	PRG_FOR

	POP	D
	POP	B
	STC
	RET
	
100$:
	POP	H
	POP	D
	POP	B
	ORA	A
	RET

;*********************************************************
;* EXP_DO_NEXT:		EXECUTE NEXT
;*			IN: C = EXECUTE
;*			OUT: CF = 1 IF MUST EXIT
EXP_DO_NEXT:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE			; CHECK EXECUTE FLAG
	JZ	1$

	CALL	PRG_NEXT		; EXECUTE NEXT
	STC
	RET
	
1$:
	ORA	A
	RET

;*********************************************************
;* EXP_DO_GOTO:		EXECUTE GOTO
;*			IN: C = EXECUTE
;*			OUT: CF = 1 IF MUST EXIT
EXP_DO_GOTO:
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ EXPRESSION
	
	PUSH	H
	CALL	EVAL_UNARYOP		; EXTRACT RESULT IN VAR_TEMP1
	
	LDA	VAR_TEMP1		; GET TYPE OF VARIABLE
	CPI	SID_CINT		; MUST BE INT
	JNZ	ERR_TYPEMISMATCH
	
	LHLD	VAR_TEMP1+1		; LOAD VALUE
	
	MVI	A,0
	ORA	H			; HI BYTE IN ACC
	JM	ERR_ILLEGAL		; VALUE MUST BE POSITIVE

	ORA	A
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	1$
	
	PUSH	B
	
	MOV	B,H			; COPY TO BC
	MOV	C,L

	CALL	PRG_GOTO		; EXECUTE GOTO
	STC

	POP	B
1$:
	POP	H	
	RET


;*********************************************************
;* EXP_DO_GOSUB:	EXECUTE GOSUB
;*			IN: B = INIF
;*			IN: C = EXECUTE
;*			OUT: CF = 1 IF MUST EXIT
EXP_DO_GOSUB:
	PUSH	B
	PUSH	D
	
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ EXPRESSION
	
	PUSH	H
	CALL	EVAL_UNARYOP		; EXTRACT RESULT IN VAR_TEMP1
	
	LDA	VAR_TEMP1		; GET TYPE OF VARIABLE
	CPI	SID_CINT		; MUST BE INT
	JNZ	ERR_TYPEMISMATCH
	
	LHLD	VAR_TEMP1+1		; LOAD VALUE
	
	MVI	A,0
	ORA	H			; HI BYTE IN ACC
	JM	ERR_ILLEGAL		; VALUE MUST BE POSITIVE

	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	1$

	MOV	D,B			; COPY INIF FLAG TO D

	MOV	B,H			; COPY TO BC
	MOV	C,L

	POP	H			; RESTORE ADDRESS

	CALL	PRG_GOSUB		; EXECUTE GOSUB

	POP	D
	POP	B
	STC	
	RET

1$:	; EXECUTE = FALSE
	POP	H
	POP	D
	POP	B
	ORA	A	
	RET

;*********************************************************
;* EXP_DO_POKE: 	EXECUTE POKE
;*			IN: C = EXECUTE
EXP_DO_POKE:
	PUSH	D
	
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ FIRST PARAM (ADDRESS)
	
	CALL	EXP_SKIPWHITESPACE
	
	MOV	A,M			; CHECK FOR ','
	CPI	',
	JNZ	ERR_SYNTAX
	INX	H
		
	CALL	EXP_L0			; READ SECOND PARAM (VALUE)

	PUSH	H
	CALL	EVAL_BINARYOP		; GET PARAMETERS IN VAR_TEMP1&2
	
	LDA	VAR_TEMP1		; CHECK TYPE OF PARAM 1
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT
	
	LDA	VAR_TEMP2		; CHECK TYPE OF PARAM 2
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ 	100$

	; VALIDATION OF VALUES	
	LHLD	VAR_TEMP1+1		; READ PARAM1 IN HL (VALUE)
	MVI	A,0
	ORA	H			; HI BYTE OF Y
	JNZ	ERR_ILLEGAL		; CHECK 0..255
	MOV	E,L			; COPY VALUE TO E
	
	LHLD	VAR_TEMP2+1		; READ ADDRESS IN HL
	
	MOV	M,E			; DO IT
	
100$:
	POP	H
	POP	D
	RET

;*********************************************************
;* EXP_DO_SLEEP: 	EXECUTE SLEEP
;*			(DELAY OF VAL * 1/10 SECONDS)
;*			IN: C = EXECUTE
EXP_DO_SLEEP:
	PUSH	D
	
	INX	H			; SKIP KEYWORD
	
	CALL	EXP_L0			; READ PARAM
	
	CALL	EXP_SKIPWHITESPACE
	
	PUSH	H
	CALL	EVAL_UNARYOP 		; GET PARAMETER IN VAR_TEMP1
	
	LDA	VAR_TEMP1		; CHECK TYPE OF PARAM 1
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ 	100$

	; VALIDATION OF VALUES
	LHLD	VAR_TEMP1+1		; READ PARAM IN HL
	MVI	A,0
	ORA	H			; HI BYTE OF Y
	JNZ	ERR_ILLEGAL		; CHECK 0..255
	MOV	A,L			; COPY VALUE TO ACC
	
	CALL	IO_DELAY		; DO IT
	
100$:
	POP	H
	POP	D
	RET

;*********************************************************
;* EXP_DO_BEEP: 	EXECUTE BEEP
;*			(DIRECT CALL TO IO LIBRARY)
;*			IN: C = EXECUTE
EXP_DO_BEEP:
	INX	H			; SKIP KEYWORD

	MOV	A,C
	CPI	FALSE
	RZ
	
	CALL	IO_BEEP
	RET

;*********************************************************
;* EXP_DO_COLOR: 	EXECUTE COLOR
;*			IN: C = EXECUTE
EXP_DO_COLOR:
	PUSH	B
	PUSH	D
	
	INX	H			; SKIP KEYWORD

	CALL	EXP_L0			; READ FIRST PARAM
	PUSH	H
		
	CALL	EXP_ISSTACKEMPTY	; CHECK IF THERE IS SOMETHING
	JC	1$

	CALL	EVAL_UNARYOP 		; GET PARAMETER IN VAR_TEMP1
	
	LDA	VAR_TEMP1		; CHECK TYPE OF PARAM 1
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT

	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	1$
	
	; VALIDATION OF VALUE
	LHLD	VAR_TEMP1+1		; READ PARAM IN HL
	MVI	A,0
	ORA	H			; HI BYTE OF Y
	JNZ	ERR_ILLEGAL		; CHECK 0..255
	MOV	A,L			; COPY VALUE TO ACC
	CPI	16			; CHECK 0..15
	JAE	ERR_ILLEGAL
	
	CALL	IO_SETFG		; DO IT
	
	
1$:	; CHECK IF SECOND PARAM IS PRESENT
	POP	H
	CALL	EXP_SKIPWHITESPACE
	
	MOV	A,M			; READ CURR CHAR
	CPI	',			; CHECK FOR OPTIONAL SEPARATOR
	JNZ	3$
	
	INX	H			; SKIP ','
	
	CALL	EXP_L0			; READ SECOND PARAM

	PUSH	H
		
	CALL	EVAL_UNARYOP 		; GET PARAMETER IN VAR_TEMP1
	
	LDA	VAR_TEMP1		; CHECK TYPE OF PARAM 1
	CPI	SID_CINT
	JNZ	ERR_TYPEMISMATCH	; MUST BE INT

	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	2$
	
	; VALIDATION OF VALUE
	LHLD	VAR_TEMP1+1		; READ PARAM IN HL
	MVI	A,0
	ORA	H			; HI BYTE OF Y
	JNZ	ERR_ILLEGAL		; CHECK 0..255
	MOV	A,L			; COPY VALUE TO ACC
	CPI	16			; CHECK 0..15
	JAE	ERR_ILLEGAL
	
	CALL	IO_SETBG		; DO IT
2$:	
	POP	H
	
3$:
	POP	D
	POP	B
	RET


;*********************************************************
;* EXP_DO_INPUT: 	EXECUTE INPUT
;*			IN: C = EXECUTE
EXP_DO_INPUT::
	PUSH	B
	PUSH	D
	
	INX	H			; SKIP KEYWORD

	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	; CHECK FOR CONST STRING
	MOV	A,M			; READ CURR CHAR
	CPI	SID_CSTR		; CHECK IF STRING
	JNZ	4$
	
	INX	H			; SKIP ID
	
	MOV	B,M			; READ LENGTH IN B
	INX	H			; SKIP LENGTH
	
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	1$
	
	CALL	IO_PUTSN		; PRINT THE STRING
		
1$:
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE
	
	; CHECK FOR ';' OR ','
	MOV	A,M
	CPI	';
	JZ	3$
	CPI	',
	JZ	2$
	JMP	ERR_SYNTAX
	
2$:	; PRINT QUESTION MARK
	MOV	A,C			; CHECK EXECUTE FLAG
	CPI	FALSE
	JZ	3$
	
	MVI	A,'?			; PRINT '?'
	CALL	IO_PUTC


3$:	; SKIP ',' OR ';'
	INX	H

4$:	; CHECK VARIABLE TO READ
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE

	MOV	A,M			; READ CURR CHAR
	CPI	SID_VAR			; CHECK TYPE
	JNZ	ERR_SYNTAX		; MUST BE VARIABLE
	
	INX	H			; SKIP TYPE
	
	MOV	E,C			; COPY EXECUTE FLAG TO E
	
	MOV	B,M			; READ VARIABLE TAG IN BC
	INX	H
	MOV	C,M
	INX	H
	
	MOV	A,E
	CPI	FALSE
	JZ	7$
	
	PUSH	H

	CALL	IO_SETINPUTMODE		; SWITCH TO INPUT MODE (TERM)
	CALL	EXP_READLINE		; READ A LINE INTO THE INPUT BUFFER
	CALL	IO_SETINTERACTIVEMODE	; SWITCH TO INTERACTIVE MODE (TERM)
	
	MOV	A,B			; TAG[0] IN ACC
	ORA	A
	JM	6$
	
	; LOAD DATA IN INT VARIABLE
	
	LXI	H,EXP_INBUFFER		; INPUT BUFFER PTR IN HL
	CALL	EXP_SKIPWHITESPACE	; SKIP WHITESPACE

	; CHECK IF THERE IS REALLY A NUMERIC VALUE
	MOV	A,M			; READ CURRENT CHAR
	CPI	'+
	JZ	5$
	CPI	'-
	JZ	5$
	CALL	C_ISDIGIT
	JC	5$
	
	; NOT A NUMBER
	JMP	ERR_TYPEMISMATCH
	
5$:	; VALID NUMBER - CONVERT TO INT AND ASSIGN TO VARIABLE
	MVI	A,SID_CINT		; FLAG AS INT
	STA	VAR_TEMP1		
	
	CALL	INT_ATOI		; CONVERT TO NUMBER (IN INT_ACC0)
	LHLD	INT_ACC0		; READ BACK VALUE
	SHLD	VAR_TEMP1+1		; PUT IN VAR_TEMP1
	
	LXI	H,VAR_TEMP1
	CALL	VAR_SET			; ASSIGN VAR = VALUE
	
	POP	H
	JMP	7$
		
6$:	; LOAD IN STRING VARIABLE
	MVI	A,SID_CSTR		; FLAG AS STRING
	STA	VAR_TEMP1
		
	LDA	EXP_INBUFFERLEN		; LENGTH OF STRING
	STA	VAR_TEMP1+1

	LXI	H,EXP_INBUFFER		; BEGIN OF INPUT DATA
	SHLD	VAR_TEMP1+2		; IN VARIABLE

	LXI	H,VAR_TEMP1		
	CALL	VAR_SET			; ASSIGN VAR = STR
	
	POP	H
	
7$:	
	POP	D
	POP	B
	RET


;*********************************************************
;* EXP_L0:  LEVEL 0 (AND/OR/XOR)
EXP_L0::
	PUSH	B
	PUSH	D

	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	CALL 	EXP_L1				; READ L1 EXP
	
1$:
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR AND/OR/XOR
	CPI	K_AND
	JZ	2$
	
	CPI	K_OR
	JZ	2$
	
	CPI	K_XOR
	JZ	2$
	
	POP	D
	POP	B	
	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L1				; READ L1 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	JMP	1$				; LOOP


;*********************************************************
;* EXP_L1:  LEVEL 1 (NOT)
EXP_L1:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR NOT
	CPI	K_NOT
	JZ	2$
	
	CALL	EXP_L2				; READ L2 EXP
	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L1				; READ L1 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	RET

;*********************************************************
;* EXP_L2:  LEVEL 2 (= <> < > <= >=)
EXP_L2:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	CALL 	EXP_L3				; READ L3 EXP
	
1$:
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR < > <= >= = <>
	CPI	K_NOTEQUAL
	JZ	2$
	
	CPI	K_LESSEQUAL
	JZ	2$
	
	CPI	K_GREATEREQUAL
	JZ	2$

	CPI	K_LESS
	JZ	2$

	CPI	K_GREATER
	JZ	2$

	CPI	K_EQUAL
	JZ	2$
	
	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L3				; READ L3 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	JMP	1$				; LOOP

;*********************************************************
;* EXP_L3:  LEVEL 3 (+ -)
EXP_L3:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	CALL 	EXP_L4				; READ L4 EXP
	
1$:
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR + -
	CPI	K_ADD
	JZ	2$
	
	CPI	K_SUBSTRACT
	JZ	2$
	
	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L4				; READ L4 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	JMP	1$				; LOOP

;*********************************************************
;* EXP_L4:  LEVEL 4 (* /)
EXP_L4:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	CALL 	EXP_L5				; READ L5 EXP
	
1$:
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR * /
	CPI	K_MULTIPLY
	JZ	2$
	
	CPI	K_DIVIDE
	JZ	2$
	
	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L5				; READ L5 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	JMP	1$				; LOOP

;*********************************************************
;* EXP_L5:  LEVEL 5 (UNARY -)
EXP_L5:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR UNARY -
	CPI	K_NEGATE
	JZ	2$
	
	CALL	EXP_L6				; READ L6 EXP
	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L5				; READ L5 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	RET


;*********************************************************
;* EXP_L6:  LEVEL 6 (POWER ^)
EXP_L6:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	CALL 	EXP_L7				; READ L7 EXP
	
1$:
	MOV	A,M				; READ CURR TOKEN

	; CHECK FOR ^
	CPI	K_POWER
	JZ	2$

	RET

2$:
	INX	H				; CURRIN++
	
	PUSH	PSW
	CALL	EXP_L7				; READ L7 EXP
	POP	PSW
	
	CALL	EVAL_EVALUATE			; EVALUATE EXPRESSION
	JMP	1$				; LOOP

;*********************************************************
;* EXP_L7:  LEVEL 7 ( (), INT, VAR, STR)
EXP_L7:
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES

	MOV	A,M				; READ CURRENT CHAR
	
	CPI	SID_CINT			; CHECK FOR INTEGER
	JZ	1$
	
	CPI	SID_VAR				; CHECK FOR VAR
	JZ	2$
	
	CPI	SID_CSTR			; CHECK FOR STRING
	JZ	3$


	CPI	'(				; EXPRESSION IN '()'
	JZ	4$

	MOV	B,A
	ANI	0xE0				; FUNCTIONS (0xAX & 0xBX)
	CPI	0xA0
	MOV	A,B
	JZ	5$

	JMP	9$

1$:
	CALL	EXP_PUSH
	INX	H
	INX	H
	INX	H
	JMP	9$

2$:
	CALL	EXP_PUSH
	INX	H
	INX	H
	INX	H
	JMP	9$

3$:
	STA	VAR_TEMP1			; SET VAR_TEMP1
	INX	H
	
	MOV	A,M				; LENGTH
	STA	VAR_TEMP1+1
	INX	H
	
	MOV	C,A				; LENGTH IN B-C
	MVI	B,0		

	MOV	A,L
	STA	VAR_TEMP1+2			; LO BYTE OF STR ADDRESS
	
	MOV	A,H
	STA	VAR_TEMP1+3			; HI BYTE OF STR ADDRESS

	DAD	B				; MOVE TO END OF STRING

	PUSH	H
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL
	CALL	EXP_PUSH
	
	POP	H
		
	JMP	9$

4$:
	INX	H				; SKIP '('
	
	CALL	EXP_L0				; READ EXPRESSION
	
	MOV	A,M				; CHECK FOR ')'
	CPI	')
	JNZ	ERR_SYNTAX
	
	INX	H				; SKIP ')'
	
	JMP	9$

5$:
	PUSH	PSW				; SAVE CURRENT TOKEN
	
	INX	H				; SKIP KEYWORD
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	MOV	A,M				; READ CURRENT CHAR
	CPI	'(				; CHECK FOR '('
	JNZ	ERR_SYNTAX
	
	INX	H				; SKIP '('
	
	CALL	EXP_L0				; READ EXPRESSION
	
	POP	PSW				; RESTORE CURRENT TOKEN
	PUSH	PSW				; PUT IT BACK FOR LATER
	
	; WATCH FOR FUNCTIONS TAKING MORE THAN 1 PARAMETER
	CPI	K_LEFT				; LEFT$(1,2)
	JZ	8$				; 2 PARAMS	
	
	CPI	K_RIGHT				; RIGHT$(1,2)
	JZ	8$				; 2 PARAMS
	
	CPI	K_MID				; MID$(1,2,3)
	JZ	7$				; 3 PARAMS
6$:	
	MOV	A,M				; READ CURRENT CHAR
	CPI	')				; LOOK FOR ')'
	JNZ	ERR_SYNTAX
	
	INX	H				; SKIP ')'
	
	POP	PSW				; GET BACK TOKEN
	CALL	EVAL_EVALUATE
	
	JMP	9$

7$:
	MOV	A,M				; READ CURRENT CHAR
	CPI	',				; CHECK FOR ','
	JNZ	ERR_SYNTAX
	
	INX	H				; SKIP ','
	
	CALL	EXP_L0				; READ EXPRESSION

8$:	
	MOV	A,M				; READ CURRENT CHAR
	CPI	',				; CHECK FOR ','
	JNZ	ERR_SYNTAX
	
	INX	H				; SKIP ','
	
	CALL	EXP_L0				; READ EXPRESSION

	JMP	6$

9$:	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	RET


;*********************************************************
;* EXP_SKIPWHITESPACE:  SKIPS SPACES IN INPUT STR (H-L)
EXP_SKIPWHITESPACE::

1$:
	MOV	A,M				; READ CURRENT CHAR
	CPI	' 				; CHECK FOR WHITESPACE
	RNZ					; RETURN IF NOT FOUND
	INX	H
	JMP	1$

;*********************************************************
;* EXP_SKIPWHITESPACE2:  SKIPS SPACES AND ':' IN INPUT STR (H-L)
EXP_SKIPWHITESPACE2:
1$:
	MOV	A,M				; READ CURRENT CHAR
	CPI	' 				; CHECK FOR WHITESPACE
	JZ	2$
	CPI	':				; CHECK FOR ':'
	JZ	2$
	
	RET
	
2$:
	INX	H
	JMP	1$

;*********************************************************
;* EXP_CLRSTACK: 	RESETS STACK
EXP_CLRSTACK::
	PUSH	H
	LXI	H,EXP_STACKLO
	SHLD	EXP_STACKCURR
	POP	H
	RET

;*********************************************************
;* EXP_ISSTACKEMPTY:  RETURNS CF=1 IF STACK IS EMPTY
EXP_ISSTACKEMPTY::
	PUSH	H
	
	LHLD	EXP_STACKCURR			; STACK PTR

	; CHECK IF STACK IS EMPTY
	MVI	A,>(EXP_STACKLO)		; CHECK HI BYTE
	CMP	H
	JNZ	1$
	
	MVI	A,<(EXP_STACKLO)		; CHECK LO BYTE
	CMP	L
	JNZ	1$
	
	; STACK IS EMPTY
	STC
	POP	H
	RET
	
1$:	; STACK IS NOT EMPTY
	ORA	A				; CLEAR CARRY FLAG
	POP	H
	RET

;*********************************************************
;* EXP_PUSH:  PUSHES DATA AT (H-L) ON EXP STACK
;*	      *MODIFIES D-E*
EXP_PUSH::
	PUSH	D
	PUSH	H

	XCHG					; HL <-> DE
	LHLD	EXP_STACKCURR			; READ CURR STACK POS IN HL
	XCHG					; HL <-> DE

	; CHECK IF STACK IS FULL
	MVI	A,>(EXP_STACKHI)		; CHECK HI BYTE
	CMP	D
	JNZ	1$
	
	MVI	A,<(EXP_STACKHI)		; CHECK LO BYTE
	CMP	E
	JZ	ERR_STACKOVERFLOW
	
1$:
	; 1	
	MOV	A,M				; READ CHAR
	STAX	D				; PUT ON STACK
	INX	H
	INX	D

	; 2	
	MOV	A,M				; READ CHAR
	STAX	D				; PUT ON STACK
	INX	H
	INX	D

	; 3	
	MOV	A,M				; READ CHAR
	STAX	D				; PUT ON STACK
	INX	H
	INX	D

	; 4	
	MOV	A,M				; READ CHAR
	STAX	D				; PUT ON STACK
	INX	H
	INX	D

	; 5
	MOV	A,M				; READ CHAR
	STAX	D				; PUT ON STACK
	INX	H
	INX	D

	; UPDATE EXP_STACKCURR
	MOV	A,E				; LO BYTE
	STA	EXP_STACKCURR
	
	MOV	A,D				; HI BYTE
	STA	EXP_STACKCURR+1

	POP	H	
	POP	D
	RET

;*********************************************************
;* EXP_POP:  SETS H-L TO TOP ITEM OF THE EXP STACK
EXP_POP::
	PUSH	D
	
	LHLD	EXP_STACKCURR

	; CHECK IF STACK IS EMPTY
	MVI	A,>(EXP_STACKLO)		; CHECK HI BYTE
	CMP	H
	JNZ	1$
	
	MVI	A,<(EXP_STACKLO)		; CHECK LO BYTE
	CMP	L
	JZ	ERR_STACKUNDERFLOW
	
1$:
	LXI	D,-5
	DAD	D			; EXP_STACKCURR -= 5
	
	SHLD	EXP_STACKCURR		; UPDATE VARIABLE

	POP	D
	RET

;*********************************************************
;* EXP_POPPUSH:  SETS H-L TO TOP ITEM OF THE EXP STACK
;*		 CURR STACK PTR STAYS THE SAME.
;*		 EQUIVALENT TO POP FOLLOWED BY PUSH
EXP_POPPUSH::
	PUSH	D
	
	LHLD	EXP_STACKCURR

	; CHECK IF STACK IS EMPTY
	MVI	A,>(EXP_STACKLO)		; CHECK HI BYTE
	CMP	H
	JNZ	1$
	
	MVI	A,<(EXP_STACKLO)		; CHECK LO BYTE
	CMP	L
	JZ	ERR_STACKUNDERFLOW
	
1$:
	LXI	D,-5
	DAD	D			; EXP_STACKCURR -= 5

	POP	D
	RET

EXP_CLEARSTACK::
	PUSH	H
	LXI	H,EXP_STACKLO		; BOTTOM OF STACK IN HL
	SHLD	EXP_STACKCURR		; CLEAR STACK
	POP	H
	RET

;*********************************************************
;* EXP_READLINE:READS A STRING INTO THE INPUT
;*		BUFFER
EXP_READLINE::
	PUSH	B
	PUSH	H
	
	MVI	C,0				; LENGTH COUNTER
	
	CALL	IO_XON
	
	LXI	H,EXP_INBUFFER			; PTR TO INPUT STR IN HL
	
1$:
	CALL	IO_GETCHAR			; READ CHARACTER FROM INBUFFER
	ORA	A				; NOCHAR
	JZ	1$
	CPI	13				; CHECK FOR (CR)
	JZ	2$
	
	MOV	M,A				; COPY CHAR TO BUFFER
	INX	H				; PTR++
	INR	C				; LENGTH++
	
	; CHECK FOR END OF BUFFER
	MVI	A,>(EXP_INBUFFEREND)		; HI BYTE
	CMP	H
	JNZ	1$
	
	MVI	A,<(EXP_INBUFFEREND)		; LO BYTE
	CMP	L
	JNZ	1$
	
	; LINE TOO LONG
	MVI	A,0
	STA	EXP_INBUFFERLEN
	STA	EXP_INBUFFER
	
	MVI	A,0xFF			
	CALL	IO_PUTC				; SEND SIGNAL TO TERM
	JMP	ERR_STRTOOLONG

2$:
	MVI	M,0				; NULL-TERMINATE STR

	MOV	A,C				; LENGTH IN ACC
	STA	EXP_INBUFFERLEN			; STORE IN VARIABLE

	CALL	IO_XOFF

	POP	H
	POP	B
	RET

;*********************************************************
;* RAM VARIABLES
;*********************************************************

.area	DATA	(REL,CON)

;*** KEEP THESE TWO TOGHETHER, IN THIS ORDER
EXP_INBUFFERLEN::	.ds	1		; LENGTH OF STRING IN INBUF
EXP_INBUFFER::		.ds 	100		; INPUT BUFFER
EXP_INBUFFEREND:
;***

EXP_STACKLO:		.ds	EXP_STACKSIZE	; EXPRESSION STACK
EXP_STACKCURR:		.ds	2		; CURRENT POS IN STACK
EXP_STACKTEMP::		.ds	5		; USED BY EXP_DO_FOR AND 

EXP_INSNEWLINE:		.ds	1		; USED BY DO_PRINT
