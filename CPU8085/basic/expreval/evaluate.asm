.module 	evaluate
.title 		Expression evaluation

.include	'expreval.def'
.include	'..\common\common.def'
.include	'..\variables\variable.def'
.include	'..\integer\integer.def'
.include	'..\strings\strings.def'

.area	_CODE


;*********************************************************
;* EVAL_EVALUATE: 	EVALUATE FUNCTION (KEYWORD IN ACC)
EVAL_EVALUATE::
	PUSH	H
	
	STA	EVAL_CURRKEYWORD

	; EVALUATE BINARY CALCULATION
	CPI	K_POWER
	JZ	1$
	CPI	K_MULTIPLY
	JZ	1$	
	CPI	K_DIVIDE
	JZ	1$
	CPI	K_ADD
	JZ	1$
	CPI	K_SUBSTRACT
	JZ	1$

	; EVALUATE BINARY RELATION	
	CPI	K_EQUAL
	JZ	2$
	CPI	K_NOTEQUAL
	JZ	2$
	CPI	K_LESS
	JZ	2$
	CPI	K_GREATER
	JZ	2$
	CPI	K_LESSEQUAL
	JZ	2$
	CPI	K_GREATEREQUAL
	JZ	2$
	
	; EVALUATE LOGICAL OPERATION (BIN)
	CPI	K_AND
	JZ	3$
	CPI	K_OR
	JZ	3$
	CPI	K_XOR
	JZ	3$
	
	; NEGATION (UNARY)
	CPI	K_NEGATE
	JZ	4$
	
	; LOGICAL NOT (UNARY)
	CPI	K_NOT
	JZ	5$

	; ABS
	CPI	K_ABS
	JZ	6$

	; SGN
	CPI	K_SGN
	JZ	7$
	
	; PEEK
	CPI	K_PEEK
	JZ	8$

	; RND
	CPI	K_RND
	JZ	9$

	; SQR
	CPI	K_SQR
	JZ	10$
	
	; LEN
	CPI	K_LEN
	JZ	11$

	; ASC
	CPI	K_ASC
	JZ	12$

	; VAL
	CPI	K_VAL
	JZ	13$

	; CHR$
	CPI	K_CHR
	JZ	14$

	; STR$
	CPI	K_STR
	JZ	15$

	; LEFT$
	CPI	K_LEFT
	JZ	16$

	; RIGHT$
	CPI	K_RIGHT
	JZ	17$

	; MID$
	CPI	K_MID
	JZ	18$

	
	HLT

1$:
	CALL	EVAL_BINARYOP
	CALL	EVAL_CHECKSAMETYPE
	CALL	EVAL_BINARYCALC
	JMP	END

2$:
	CALL	EVAL_BINARYOP
	CALL	EVAL_CHECKSAMETYPE
	CALL	EVAL_BINARYREL
	JMP	END

3$:
	CALL	EVAL_BINARYOP
	CALL	EVAL_CHECKSAMETYPE
	CALL	EVAL_BINARYLOG
	JMP	END
	
4$:	
	CALL	EVAL_UNARYOP
	CALL	EVAL_NEGATE
	JMP	END
	
5$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_NOT
	JMP	END

6$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_ABS
	JMP	END

7$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_SGN
	JMP	END

8$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_PEEK
	JMP	END

9$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_RND
	JMP	END

10$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_SQR
	JMP	END
	
11$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_LEN
	JMP	END

12$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_ASC
	JMP	END

13$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_VAL
	JMP	END

14$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_CHR
	JMP	END

15$:
	CALL	EVAL_UNARYOP
	CALL	EVAL_STR
	JMP	END

16$:
	CALL	EVAL_BINARYOP
	CALL	EVAL_LEFT
	JMP	END

17$:
	CALL	EVAL_BINARYOP
	CALL	EVAL_RIGHT
	JMP	END

17$:
	CALL	EVAL_TERNARYOP
	CALL	EVAL_MID
	JMP	END
	
END:
	POP	H
	RET

;*********************************************************
;* EVAL_UNARYOP: 	EXTRACT PARAMETERS FOR UNARY
;*			OPERATION (VAR_TEMP1)
EVAL_UNARYOP:
	CALL	EVAL_COPY1
	RET

;*********************************************************
;* EVAL_BINARYOP: 	EXTRACT PARAMETERS FOR BINARY 
;*			OPERATION (VAR_TEMP1, VAR_TEMP2)
EVAL_BINARYOP:
	CALL	EVAL_COPY1
	CALL	EVAL_COPY2
	RET

;*********************************************************
;* EVAL_TERNARYOP: 	EXTRACT PARAMETERS FOR TERNARY
;*			OPERATION (VAR_TEMP1, VAR_TEMP2,
;*			VAR_TEMP3)
EVAL_TERNARYOP:
	CALL	EVAL_COPY1
	CALL	EVAL_COPY2
	CALL	EVAL_COPY3
	RET

;*********************************************************
;* EVAL_CHECKSAMSTYPE: 	CHECKS IF VAR_TEMP1 & VAR_TEMP2
;*			ARE OF SAME TYPE
EVAL_CHECKSAMETYPE:
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	MOV	B,A				; COPY TO B
	LDA	VAR_TEMP2			; TYPE OF VAR2 IN ACC
	
	CMP	B
	JNZ	1$
		
	RET

1$:	HLT

;*********************************************************
;* EVAL_BINARYCALC: 	EVALUATES BINARY CALCULATION
;*			(+, -, * /)
EVAL_BINARYCALC::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	6$
	
	; OPERATION ON INTEGERS
	
	LHLD	VAR_TEMP2+1			; HL = VAR_TEMP2 VALUE
	SHLD	INT_ACC0			; PUT IN INT_ACC0
	
	LXI	H,VAR_TEMP1+1
	
	LDA	EVAL_CURRKEYWORD		; ACC = CURR KEYWORD
	
	CPI	K_ADD
	JZ	1$
	CPI	K_SUBSTRACT
	JZ	2$
	CPI	K_MULTIPLY
	JZ	3$
	CPI	K_DIVIDE
	JZ	4$
	
	HLT
	
1$:	; ADD
	CALL	INT_ADD
	JMP	5$
	
2$:	; SUB
	CALL	INT_SUB
	JMP	5$

3$:	; MUL
	CALL	INT_MUL
	JMP	5$

4$:	; DIV
	CALL	INT_DIV
	JMP	5$
	
5$:	
	LHLD	INT_ACC0			; READ OP RESULT
	SHLD	VAR_TEMP3+1			; PUT IN VAR_TEMP3
	
	MVI	A,SID_CINT			; FLAG AS AN INT
	STA	VAR_TEMP3			; PUT AT BEGINNING OF VAR_TEMP3
	
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
6$:	; OPERATION ON STRINGS
	LDA	EVAL_CURRKEYWORD		; ACC = CURR KEYWORD
	
	CPI	K_ADD				; ONLY ADD IS PERMITTED
	JNZ	7$

	ORA	A				; CLEAR CARRY
	
	LDA	VAR_TEMP2+1			; LENGTH OF STRING 1
	MOV	B,A				; COPY TO B
	
	LDA	VAR_TEMP1+1			; LENGTH OF STRING 2

	ADD	B				; ADD LENGTHS (RESULT IN ACC)
	JC	7$				; CHECK FOR OVERFLOW
	
	STA	VAR_TEMP3+1			; STORE LENGTH IN VAR_TEMP3
	
	LXI	B,0x0000			; NO PARENT
	CALL	STR_ALLOCATE			; CREATE NEW STRING, PTR IN HL

	SHLD	VAR_TEMP3+2			; STORE PTR TO STRING IN TEMP3
	
	; CONCATENATE THE STRINGS
	XCHG					; SWAP DE<->HL
	LHLD	VAR_TEMP2+2			; ADDRESS OF STRING2 IN HL
	XCHG					; SWAP DE<->HL
	LDA	VAR_TEMP2+1			; LENGTH IN ACC
	MOV	B,A				; COPY TO B
	CALL	STR_COPY
	
	XCHG					; SWAP DE<->HL
	LHLD	VAR_TEMP1+2			; ADDRESS OF STRING1 IN HL
	XCHG					; SWAP DE<->HL
	LDA	VAR_TEMP1+1			; LENGTH IN ACC
	MOV	B,A				; COPY TO B
	CALL	STR_COPY

	MVI	A,SID_CSTR			; FLAG AS STRING
	STA	VAR_TEMP3			; PUT AT BEGINNING OF VAR_TEMP3
	
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	

7$:	
	HLT


;*********************************************************
;* EVAL_BINARYREL: 	EVALUATES BINARY RELATION
;*			(< > <= >= = <>)
EVAL_BINARYREL::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	CSTR
	
	; OPERATION ON INTEGERS
	
	LHLD	VAR_TEMP2+1			; HL = VAR_TEMP2 VALUE
	SHLD	INT_ACC0			; PUT IN INT_ACC0
	
	LXI	H,VAR_TEMP1+1
	
	CALL	INT_CMP				; COMPARE THE INTS
	MOV	B,A				; COPY RESULT IN B
	JMP	NEXT

CSTR:	; OPERATION ON STRINGS
	
	LDA	VAR_TEMP2+1			; LENGTH OF STR2 IN ACC
	MOV	B,A				; COPY TO B
	
	LDA	VAR_TEMP1+1			; LENGTH OF STR1 IN ACC
	MOV	C,A				; COPY TO C
	
	LHLD	VAR_TEMP2+2			; ADDR OF STR2PTR IN HL
	XCHG					; HL<->DE
	LHLD	VAR_TEMP1+2			; ADDR OF STR1PTR IN HL
	
	CALL	STR_CMP				; COMPARE STRINGS	
	MOV	B,A				; COPY RESULT IN B
		
NEXT:
	LDA	EVAL_CURRKEYWORD		; ACC = CURR KEYWORD

	CPI	K_EQUAL
	JZ	EQUAL
	CPI	K_NOTEQUAL
	JZ	NOTEQUAL
	CPI	K_LESS
	JZ	LESS
	CPI	K_GREATER
	JZ	GREATER
	CPI	K_LESSEQUAL
	JZ	LESSEQUAL
	CPI	K_GREATEREQUAL
	JZ	GREATEREQUAL

	HLT

EQUAL:		; =
	MVI	A,0x00				; CHECK IF B == 0
	ORA	B
	JZ	TRUE
	JMP	FALSE

NOTEQUAL:	; <>
	MVI	A,0x00				; CHECK IF B <> 0
	ORA	B
	JZ	FALSE
	JMP	TRUE

LESS:		; <
	MVI	A,0xFF				; CHECK IF B = 0xFF
	CMP	B
	JZ	TRUE
	JMP	FALSE

GREATER:	; >
	MVI	A,0x01				; CHECK IF B == 0x01
	CMP	B
	JZ	TRUE
	JMP	FALSE

LESSEQUAL:	; <=
	MVI	A,0xFF				; CHECK IF B = 0xFF
	CMP	B
	JZ	TRUE
	JMP	EQUAL				; CHECK FOR EQUALITY

GREATEREQUAL:	; >=
	MVI	A,0x01				; CHECK IF B = 0x01
	CMP	B
	JZ	TRUE
	JMP	EQUAL				; CHECK FOR EQUALITY
	
TRUE:	; TRUE
	LXI	H,0xFFFF
	JMP	IRET
	
FALSE:	; FALSE
	LXI	H,0x0000
	JMP	IRET

IRET:	
	SHLD	VAR_TEMP3+1			; PUT RESULT IN VAR_TEMP3
	
	MVI	A,SID_CINT			; FLAG AS AN INT
	STA	VAR_TEMP3			; PUT AT BEGINNING OF VAR_TEMP3
	
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	

;*********************************************************
;* EVAL_BINARYLOG: 	EVALUATES LOGICAL RELATION (BINARY)
;*			(AND OR XOR)
EVAL_BINARYLOG::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	5$				; MUST BE INTEGER
	
	LHLD	VAR_TEMP2+1			; HL = VAR_TEMP2 VALUE
	SHLD	INT_ACC0			; PUT IN INT_ACC0
	
	LXI	H,VAR_TEMP1+1
	
	LDA	EVAL_CURRKEYWORD		; ACC = CURR KEYWORD
	
	CPI	K_AND
	JZ	1$
	CPI	K_OR
	JZ	2$
	CPI	K_XOR
	JZ	3$
	
	HLT
	
1$:	; AND
	CALL	INT_AND
	JMP	4$
	
2$:	; OR
	CALL	INT_OR
	JMP	4$

3$:	; XOR
	CALL	INT_XOR
	JMP	4$

4$:	
	LHLD	INT_ACC0			; READ OP RESULT
	SHLD	VAR_TEMP3+1			; PUT IN VAR_TEMP3
	
	MVI	A,SID_CINT			; FLAG AS AN INT
	STA	VAR_TEMP3			; PUT AT BEGINNING OF VAR_TEMP3
	
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
5$:	HLT

;*********************************************************
;* EVAL_NEGATE: 	EVALUATES INTEGER NEGATION
EVAL_NEGATE::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	LXI	H,VAR_TEMP1+1
	
	CALL	INT_NEG
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT
	

;*********************************************************
;* EVAL_NOT: 	EVALUATES LOGICAL NOT
EVAL_NOT::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	LXI	H,VAR_TEMP1+1
	
	CALL	INT_NOT
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_ABS: 	EVALUATES ABSOLUTE VALUE (INT)
EVAL_ABS::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	LXI	H,VAR_TEMP1+1
	
	CALL	INT_ABS
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_SGN: 	EVALUATES SGN (INT)
EVAL_SGN::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	LXI	H,VAR_TEMP1+1
	
	CALL	INT_SGN
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_PEEK: 	EVALUATES PEEK
EVAL_PEEK::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	LHLD	VAR_TEMP1+1			; ADDRESS IN HL

	MOV	A,M				; READ MEMORY IN ACC
	MOV	L,A				; L = VALUE
	MVI	H,0				; H = 0
	
	SHLD	VAR_TEMP1+1			; PUT BACK IN VAR_TEMP1

	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_RND: 	EVALUATES RND (INT)
EVAL_RND::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	CALL	INT_RND
	
	LHLD	INT_ACC0			; READ BACK VALUE IN HL
	SHLD	VAR_TEMP1+1			; SAVE IN VAR_TEMP1

	MVI	A,SID_CINT			; FLAG AS AN INT
	STA	VAR_TEMP1			; PUT AT BEGINNING OF VAR_TEMP1

	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT


;*********************************************************
;* EVAL_SQR: 	EVALUATES SQR (INT)
EVAL_SQR::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JZ	1$				; MUST BE INTEGER
	
	LXI	H,VAR_TEMP1+1
	
	CALL	INT_SQR

	LHLD	INT_ACC0			; READ BACK VALUE IN HL
	SHLD	VAR_TEMP1+1			; SAVE IN VAR_TEMP1
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_LEN: 	EVALUATES LEN (STR)
EVAL_LEN::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JNZ	1$				; MUST BE STRING
	
	MVI	A,SID_CINT			; FLAG AS AN INT
	STA	VAR_TEMP1			; PUT AT BEGINNING OF VAR_TEMP1
	
	; 	VAR_TEMP1+1 ALREADY CONTAINS LO BYTE OF STR LENGTH
	
	MVI	A,0
	STA	VAR_TEMP1+2			; HI BYTE OF LENGTH
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_ASC: 	EVALUATES ASC (STR)
EVAL_ASC::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JNZ	1$				; MUST BE STRING
	
	LDA	VAR_TEMP1+1			; READ STRING LENGTH
	ORA	A				; CHECK IF ZERO
	JZ	1$
	
	LHLD	VAR_TEMP1+2			; READ ADDRESS OF STRING DATA

	MVI	A,SID_CINT			; FLAG AS INT
	STA	VAR_TEMP1			; PUT AT BEGINNING OF VAR_TEMP1
	
	MOV	A,M				; READ FIRST CHAR IN ACC
	STA	VAR_TEMP1+1			; PUT AS LO BYTE
	
	MVI	A,0
	STA	VAR_TEMP1+2			; HI BYTE = 0
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_VAL: 	EVALUATES VAL (STR)
EVAL_VAL::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CSTR
	JNZ	1$				; MUST BE STRING
	
	LDA	VAR_TEMP1+1			; READ STRING LENGTH
	ORA	A				; CHECK IF ZERO
	JZ	1$
	
	LHLD	VAR_TEMP1+2			; READ ADDRESS OF STRING DATA

	CALL	INT_ATOI			; CONVERT TO INT, 
		
	LHLD	INT_ACC0			; READ RESULT
	SHLD	VAR_TEMP1+1			; COPY TO VAR_TEMP1
	
	MVI	A,SID_CINT			; FLAG AS INT
	STA	VAR_TEMP1			; PUT AT BEGINNING OF VAR_TEMP1
	
	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_CHR: 	EVALUATES CHR$ (STR)
EVAL_CHR::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CINT
	JNZ	1$				; MUST BE INTEGER
	
	LDA	VAR_TEMP1+2			; READ HI BYTE OF INT IN ACC
	ORA	A
	JNZ	1$	

	MVI	A,1				; LENGTH OF STRING
	LXI	B,0x0000			; NO PARENT
	CALL	STR_ALLOCATE			; ALLOCATE STRING OF 1 CHAR	

	LDA	VAR_TEMP1+1			; READ LO BYTE OF INT IN ACC
	MOV	M,A				; SAVE IN NEW STRING
	
	MVI	A,SID_CSTR			; FLAG AS STRING
	STA	VAR_TEMP1			; PUT AT BEGINNING OF VAR_TEMP1
	
	MVI	A,1				; LENGTH
	STA	VAR_TEMP1+1
	
	SHLD	VAR_TEMP1+2			; PTR TO STRING

	LXI	H,VAR_TEMP1			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_STR: 	EVALUATES STR$ (STR)
EVAL_STR::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CINT
	JNZ	1$				; MUST BE INTEGER

	LHLD	VAR_TEMP1+1			; READ VALUE IN HL
	SHLD	INT_ACC0			; PUT IN INT_ACC0
	
	MVI	A,SID_CSTR			; FLAG AS STRING
	STA	VAR_TEMP2
	
	CALL	INT_ITOA			; CONVERT TO STRING
	XCHG					; ADDRESS OF STRING IN DE
						; LENGTH IS IN ACC

	STA	VAR_TEMP2+1			; PUT LENGTH IN VAR_TEMP2
	
	LXI	B,0x0000			; NO PARENT
	CALL	STR_ALLOCATE			; ALLOCATE NEW STRING
	
	SHLD	VAR_TEMP2+2			; PUT NEW STRPTR IN VAR_TEMP2
	
	MOV	B,A				; COPY LENGTH TO B	
	CALL	STR_COPY			; COPY STRING		
	
	LXI	H,VAR_TEMP2			; ADDRESS OF VAR_TEMP1 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_LEFT: EVALUATES LEFT$ (STR)
EVAL_LEFT::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CINT
	JNZ	1$				; MUST BE INTEGER

	LHLD	VAR_TEMP1+1			; LOAD LENGTH IN HL
	MOV	A,H				; HI BYTE IN ACC
	ORA	A				; MUST BE ZERO
	JNZ	1$				; (0..255)
	
	LDA	VAR_TEMP2			; TYPE OF VAR2 IN ACC
	CPI	SID_CSTR
	JNZ	1$				; MUST BE STRING

	LDA	VAR_TEMP2+1			; LENGTH OF STRING IN ACC
	
	CMP	L				; CHECK IF SIZE > STR LENTGH
	JAE	2$
	
	MOV	L,A
	
2$:
	MVI	A,SID_CSTR			; FLAG AS STRING
	STA	VAR_TEMP3
	
	MOV	A,L				; LENGTH OF SUBSTRING
	STA	VAR_TEMP3+1
	
	LXI	B,0x0000			; NO PARENT
	CALL	STR_ALLOCATE			; CREATE NEW STRING
						; ADDR IN H-L
	SHLD	VAR_TEMP3+2
	XCHG					; HL<->DE
	
	MOV	B,A				; LENGTH TO COPY IN B
	LHLD	VAR_TEMP2+2			; SOURCE STRING
	XCHG
	CALL	STR_COPY			; COPY STRING
		
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT


;*********************************************************
;* EVAL_RIGHT: EVALUATES RIGHT$ (STR)
EVAL_RIGHT::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CINT
	JNZ	1$				; MUST BE INTEGER

	LHLD	VAR_TEMP1+1			; LOAD LENGTH IN HL
	MOV	A,H				; HI BYTE IN ACC
	ORA	A				; MUST BE ZERO
	JNZ	1$				; (0..255)
	
	XCHG					; SWAP HL<->DE
	
	LDA	VAR_TEMP2			; TYPE OF VAR2 IN ACC
	CPI	SID_CSTR
	JNZ	1$				; MUST BE STRING

	LDA	VAR_TEMP2+1			; LENGTH OF STRING IN ACC
	
	LHLD	VAR_TEMP2+2			; SOURCE STRING
	MOV	C,A				; COPY 0/SIZE IN B/C
	MVI	B,0				;
	DAD	B				; ADD SIZE TO SOURCE PTR	
	
	CMP	E				; CHECK IF SIZE > STR LENTGH
	JAE	2$
	
	MOV	E,A
	
2$:
	MOV	A,E				; LENGTH OF SUBSTRING
	STA	VAR_TEMP3+1
	
	CMA					; LEN = ~LEN
	MOV	C,A				; COPY -LEN IN B-C
	INR	C
	MVI	B,0xFF				;
	DAD	B				; SUBSTRACT LEN FROM SOURCE PTR
	SHLD	VAR_TEMP2+2			; PUT BACK IN VAR_TEMP2

	MVI	A,SID_CSTR			; FLAG AS STRING
	STA	VAR_TEMP3

	MOV	A,E
	
	LXI	B,0x0000			; NO PARENT
	CALL	STR_ALLOCATE			; CREATE NEW STRING
						; ADDR IN H-L
	SHLD	VAR_TEMP3+2
	XCHG					; HL<->DE
	
	MOV	B,A				; LENGTH TO COPY IN B
	LHLD	VAR_TEMP2+2			; SOURCE STRING
	XCHG
	CALL	STR_COPY			; COPY STRING
		
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET	
	
1$:	HLT

;*********************************************************
;* EVAL_RIGHT:	EVALUATES MID$ (STR)
;* 		VAR_TEMP3: SOURCE STRING
;*		VAR_TEMP2: POS IN SOURCE STRING
;*		VAR_TEMP1: LENGTH OF SUBSTRING
EVAL_MID::
	LDA	VAR_TEMP1			; TYPE OF VAR1 IN ACC
	CPI	SID_CINT
	JNZ	1$				; MUST BE INTEGER

	LDA	VAR_TEMP2			; TYPE OF VAR2 IN ACC
	CPI	SID_CINT
	JNZ	1$				; MUST BE INTEGER

	LDA	VAR_TEMP3			; TYPE OF VAR3 IN ACC
	CPI	SID_CSTR
	JNZ	1$				; MUST BE STRING



;;;;;;;;;;;;;;;;;
		
	LXI	H,VAR_TEMP3			; ADDRESS OF VAR_TEMP3 IN HL	
	CALL	EXP_PUSH			; PUSH RESULT ON STACK
	
	RET
	
1$:	HLT

;*********************************************************
;* EVAL_COPY1: 	POP FROM EXP STACK AND COPY VAR TO VAR_TEMP1
EVAL_COPY1:
	CALL	EXP_POP				; ADDR OF DATA IN H-L
	
	MOV	A,M				; DATA TYPE IN ACC
	
	CPI	SID_VAR				; CHECK IF VAR
	JZ	VAR
	
	STA	VAR_TEMP1			; BYTE 1
	INX	H
	
	MOV	A,M
	STA	VAR_TEMP1+1			; BYTE 2
	INX	H
	
	MOV	A,M				; BYTE 3
	STA	VAR_TEMP1+2
	INX	H

	MOV	A,M				; BYTE 4
	STA	VAR_TEMP1+3
	INX	H
	
	RET
		
;*********************************************************
;* EVAL_COPY2: 	POP FROM EXP STACK AND COPY VAR TO VAR_TEMP2
EVAL_COPY2:
	CALL	EXP_POP				; ADDR OF DATA IN H-L
	
	MOV	A,M				; DATA TYPE IN ACC
	
	CPI	SID_VAR				; CHECK IF VAR
	JZ	VAR
	
	STA	VAR_TEMP2			; BYTE 1
	INX	H
	
	MOV	A,M
	STA	VAR_TEMP2+1			; BYTE 2
	INX	H
	
	MOV	A,M				; BYTE 3
	STA	VAR_TEMP2+2
	INX	H

	MOV	A,M				; BYTE 4
	STA	VAR_TEMP2+3
	INX	H
	
	RET

;*********************************************************
;* EVAL_COPY3: 	POP FROM EXP STACK AND COPY VAR TO VAR_TEMP3
EVAL_COPY3:
	CALL	EXP_POP				; ADDR OF DATA IN H-L
	
	MOV	A,M				; DATA TYPE IN ACC
	
	CPI	SID_VAR				; CHECK IF VAR
	JZ	VAR
	
	STA	VAR_TEMP3			; BYTE 1
	INX	H
	
	MOV	A,M
	STA	VAR_TEMP3+1			; BYTE 2
	INX	H
	
	MOV	A,M				; BYTE 3
	STA	VAR_TEMP3+2
	INX	H

	MOV	A,M				; BYTE 4
	STA	VAR_TEMP3+3
	INX	H
	
	RET


VAR:
	HLT


;*********************************************************
;* RAM VARIABLES
;*********************************************************

.area	DATA	(REL,CON)

EVAL_CURRKEYWORD:	.ds	1		; CURRENT KEYWORD