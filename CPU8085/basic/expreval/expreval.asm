.module 	expreval
.title 		Expression evaluation

.include	'..\common\common.def'
.include	'..\variables\variable.def'
.include	'..\integer\integer.def'
.include	'..\io\io.def'
.include	'..\error\error.def'
.include	'..\program\program.def'
.include	'evaluate.def'


.area	_CODE

EXP_STACKSIZE 	= 128
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

LOOP:
	CALL	EXP_SKIPWHITESPACE2		; SKIP SPACES AND ':'

	MOV	A,M				; READ CURR CHAR
	ORA	A
	JZ	EXIT
	
	CPI	K_LIST				; CHECK FOR LIST
	JZ	LIST
	
	JMP	ERR_UNKNOWN
	
CONT:	
	CALL	EXP_SKIPWHITESPACE
	
	MOV	A,M				; READ CURR CHAR
	CPI	':				; LOOP IF ':' OR 'ELSE'
	JZ	LOOP
	CPI	K_ELSE
	JZ	LOOP
	CPI	0
	JZ	EXIT
	
	JMP	ERR_UNKNOWN

LIST:	; LIST
	CALL	EXP_DO_LIST
	JMP	CONT


EXIT:
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


;*********************************************************
;* EXP_L0:  LEVEL 0 (AND/OR/XOR)
EXP_L0::
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
	JZ	INT
	
	CPI	SID_VAR				; CHECK FOR VAR
	JZ	VAR
	
	CPI	SID_CSTR			; CHECK FOR STRING
	JZ	STR


	CPI	'(				; EXPRESSION IN '()'
	JZ	EXPR

	MOV	B,A
	ANI	0xE0				; FUNCTIONS (0xAX & 0xBX)
	CPI	0xA0
	MOV	A,B
	JZ	FUNC

	JMP	END

INT:
	CALL	EXP_PUSH
	INX	H
	INX	H
	INX	H
	JMP	END

VAR:
	CALL	EXP_PUSH
	INX	H
	INX	H
	INX	H
	JMP	END

STR:
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
		
	JMP	END

EXPR:
	INX	H				; SKIP '('
	
	CALL	EXP_L0				; READ EXPRESSION
	
	MOV	A,M				; CHECK FOR ')'
	CPI	')
	JNZ	ERR_EXP_SYNTAX
	
	INX	H				; SKIP ')'
	
	JMP	END

FUNC:
	PUSH	PSW				; SAVE CURRENT TOKEN
	
	INX	H				; SKIP KEYWORD
	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	
	MOV	A,M				; READ CURRENT CHAR
	CPI	'(				; CHECK FOR '('
	JNZ	ERR_EXP_SYNTAX
	
	INX	H				; SKIP '('
	
	CALL	EXP_L0				; READ EXPRESSION
	
	POP	PSW				; RESTORE CURRENT TOKEN
	PUSH	PSW				; PUT IT BACK FOR LATER
	
	; WATCH FOR FUNCTIONS TAKING MORE THAN 1 PARAMETER
	CPI	K_LEFT				; LEFT$(1,2)
	JZ	F2				; 2 PARAMS	
	
	CPI	K_RIGHT				; RIGHT$(1,2)
	JZ	F2				; 2 PARAMS
	
	CPI	K_MID				; MID$(1,2,3)
	JZ	F3				; 3 PARAMS
FRET:	
	MOV	A,M				; READ CURRENT CHAR
	CPI	')				; LOOK FOR ')'
	JNZ	ERR_EXP_SYNTAX
	
	INX	H				; SKIP ')'
	
	POP	PSW				; GET BACK TOKEN
	CALL	EVAL_EVALUATE
	
	JMP	END

F3:
	MOV	A,M				; READ CURRENT CHAR
	CPI	',				; CHECK FOR ','
	JNZ	ERR_EXP_SYNTAX
	
	INX	H				; SKIP ','
	
	CALL	EXP_L0				; READ EXPRESSION

F2:	
	MOV	A,M				; READ CURRENT CHAR
	CPI	',				; CHECK FOR ','
	JNZ	ERR_EXP_SYNTAX
	
	INX	H				; SKIP ','
	
	CALL	EXP_L0				; READ EXPRESSION

	JMP	FRET

END:	CALL	EXP_SKIPWHITESPACE		; SKIP SPACES
	RET


;*********************************************************
;* EXP_SKIPWHITESPACE:  SKIPS SPACES IN INPUT STR (H-L)
EXP_SKIPWHITESPACE:

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
;* EXP_SKIPWHITESPACE3:  SKIPS SPACES,':'And K_ELSE IN INPUT STR (H-L)
EXP_SKIPWHITESPACE3:
1$:
	MOV	A,M				; READ CURRENT CHAR
	CPI	' 				; CHECK FOR WHITESPACE
	JZ	2$
	CPI	':				; CHECK FOR ':'
	JZ	2$
	CPI	K_ELSE
	JZ	2$
	
	RET
	
2$:
	INX	H
	JMP	1$


;*********************************************************
;* EXP_PUSH:  PUSHES DATA AT (H-L) ON EXP STACK
;*	      *MODIFIES D-E*
;*	TODO: ADD VALIDATION
EXP_PUSH::
	PUSH	H

	XCHG					; HL <-> DE
	LHLD	EXP_STACKCURR			; READ CURR STACK POS IN HL
	XCHG					; HL <-> DE

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

	; UPDATE EXP_STACKCURR
	MOV	A,E				; LO BYTE
	STA	EXP_STACKCURR
	
	MOV	A,D				; HI BYTE
	STA	EXP_STACKCURR+1

	POP	H	
	RET

;*********************************************************
;* EXP_POP:  SETS H-L TO TOP ITEM OF THE EXP STACK
;*	      *MODIFIES D-E*
;*	TODO: ADD VALIDATION
EXP_POP::
	LHLD	EXP_STACKCURR
	
	LXI	D,-4
	DAD	D			; EXP_STACKCURR -= 5
	
	SHLD	EXP_STACKCURR		; UPDATE VARIABLE

	RET

.if DEBUG
EXP_DUMPSTACK::
	PUSH	B
	PUSH	D
	PUSH	H
	
	LXI	H,EXP_STACKLO		; BOTTOM OF STACK IN HL
	XCHG				; HL<->DE
	
	LHLD	EXP_STACKCURR		; CURRENT STACK POS IN HL
	
1$:
	MOV	A,L			; CHECK IF BOTTOM OF STACK
	CMP	E			; COMPARE LOW BYTE
	JNZ	2$
	
	MOV	A,H
	CMP	D			; COMPARE HI BYTE
	JNZ	2$
	
	; END OF STACK
	CALL	IO_PUTCR	
	POP	H
	POP	D
	POP	B
	RET
	
2$:
	LXI	B,-4			; GO BACK 4 BYTES
	DAD	B			; CURRPOS -= 4
	
	PUSH	H			; KEEP FOR LATER
	
	MOV	A,M
	CPI	SID_CINT
	JZ	4$
	
	CPI	SID_CSTR
	JZ	5$
	
	CPI	SID_VAR
	JZ	6$

3$:
	POP	H			; RESTORE PLACE IN STACK
	JMP	1$
		
	RET
	
4$:	; PRINT CONST INT
	PUSH	H
	LXI	H,SINTSTR
	CALL	IO_PUTS
	POP	H
	
	INX	H			; HL++
	MOV	A,M			; LO BYTE OF INT IN ACC
	STA	INT_ACC0
	
	INX	H			; HL++
	MOV	A,M			; HI BYTE OF INT IN ACC
	STA	INT_ACC0+1
	
	CALL	INT_ITOA		; CONVERT TO STRING
	CALL	IO_PUTS			; PRINT IT
		
	MVI	A,']
	CALL	IO_PUTC
	JMP	3$
	
5$:	; PRINT CONST STR
	PUSH	H
	LXI	H,SSTRSTR
	CALL	IO_PUTS
	POP	H
	
	INX	H			; HL++
	MOV	B,M			; LENGTH OF STR IN B
	
	PUSH	D
	PUSH	H
	
	INX	H			; HL++
	MOV	E,M			; LO BYTE OF STR PTR IN E
	
	INX	H			; HL++
	MOV	D,M			; HI BYTE OF STR PTR IN D
	
	XCHG
	
	CALL	IO_PUTSN
	
	POP	H
	POP	D
	
	MVI	A,'"
	CALL	IO_PUTC
	
	MVI	A,']
	CALL	IO_PUTC
	JMP	3$
	
6$:	; PRINT VAR
	LXI	H,SVARSTR
	CALL	IO_PUTS
	JMP	3$

SINTSTR:	.asciz	'[CI '
SSTRSTR: 	.asciz	'[CS "'
SVARSTR:	.asciz	'[VAR]'

EXP_CLEARSTACK::
	PUSH	H
	LXI	H,EXP_STACKLO		; BOTTOM OF STACK IN HL
	SHLD	EXP_STACKCURR		; CLEAR STACK
	POP	H
	RET
.endif

;*********************************************************
;* RAM VARIABLES
;*********************************************************

.area	DATA	(REL,CON)

EXP_STACKLO:	.ds	EXP_STACKSIZE	; EXPRESSION STACK
EXP_STACKCURR:	.ds	2		; CURRENT POS IN STACK
