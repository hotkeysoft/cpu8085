.module 	program
.title 		Program module

.include	'..\common\common.def'
.include	'..\error\error.def'
.include	'..\variables\variable.def'
.include	'..\integer\integer.def'
.include	'..\io\io.def'
.include	'..\tokenize\tokenize.def'

.area	_CODE

;*********************************************************
;* PRG_INIT:	INITIALIZES PROGRAM MODULE
PRG_INIT::
	MVI	A,0
	LXI	H,0				; CLEAR PTRS
	
	SHLD	PRG_NEWLINEPTR
	SHLD	PRG_CURRLINEPTR
	SHLD	PRG_CURRPOSPTR
	SHLD	PRG_NEXTRETURNPOINTPTR
	SHLD	PRG_NEXTCURRLINEPTR
	SHLD	PRG_CURRLINE	
		
	STA	PRG_ISEND
	STA	PRG_ISNEXT
	STA	PRG_INIF
	RET

;*********************************************************
;* PRG_NEW:	CLEARS PROGRAM, VARIABLES
PRG_NEW::
	LHLD	PRG_LOPTR
	SHLD	PRG_HIPTR			; CLEAR PROGRAM
	
	SHLD	VAR_LOPTR			; CLEAR VARIABLES
	SHLD	VAR_HIPTR
	
	JMP	PRG_INIT			; RESET FLAGS

;*********************************************************
;* PRG_LIST:	LISTS PROGRAM
PRG_LIST::
	LHLD	PRG_LOPTR			; BEGIN OF PROGRAM
	
1$:
	; CHECK IF END OF PROGRAM
	LDA	PRG_HIPTR			; CHECK LO BYTE
	CMP	L
	JNZ	2$
	
	LDA	PRG_HIPTR+1			; CHECK HI BYTE
	CMP	H
	JNZ	2$

	RET
	
2$:
	INX	H				; SKIP LENGTH OF LINE
	
	MOV	E,M				; LO BYTE OF LINE NO IN E
	INX	H
	MOV	D,M				; HI BYTE OF LINE NO IN D
	INX	H
	
	XCHG					; SWAP DE<->HL
	SHLD	INT_ACC0			; PUT IN INT_ACC0
	
	CALL	INT_ITOA			; CONVERT TO STRING
	CALL	IO_PUTS				; PRINT IT
	
	MVI	A,' 				; PUT SPACE
	CALL	IO_PUTC				; PRINT IT
	
	XCHG					; SWAP DE<->HL
	
	CALL	TOK_UNTOKENIZE			; PRINT LINE CONTENTS

	CALL	IO_PUTCR			; NEW LINE
	
	JMP	1$				; LOOP

;*********************************************************
;* PRG_FIND:	FINDS LINE SPECIFIED IN BC
;*		RETURNS PTR IN HL
;*		IF FOUND, CF = 1
;*		IF NOT, CF = 0 AND HL IS INSERTION POINT
PRG_FIND::
	PUSH	D

	LHLD	PRG_LOPTR			; HL->FIRST PROGRAM LINE

1$:	; CHECK IF END OF PROGRAM
	LDA	PRG_HIPTR			; CHECK LO BYTE
	CMP	L
	JNZ	2$
	
	LDA	PRG_HIPTR+1			; CHECK HI BYTE
	CMP	H
	JNZ	2$

	; 	END OF PROGRAM -> NOT FOUND
	ORA	A				; CLEAR CARRY FLAG
	POP	D
	RET

2$:
	INX	H
	MOV	E,M				; LOAD CURRENT LINE IN DE
	INX	H
	MOV	D,M
	DCX	H				; GO BACK TO BEGINNING
	DCX	H
	
	; 	BC -> LINE SEARCHED FOR
	; 	DE -> CURRENT LINE
	
	MOV	A,D				; COMPARE HI BYTE
	CMP	B
	JB	5$
	JZ	3$
	
	;	CURRENT LINE > LINE SEARCHED FOR
	ORA	A				; RESET CARRY FLAG
	POP	D
	RET
	
3$:	; 	HI BYTES ARE EQUAL, SO CHECK LO BYTES
	MOV	A,E				; COMPARE LO BYTE
	CMP	C
	JB	5$
	JZ	4$
	
	; 	CURRENT LINE > LINE SEARCHED FOR
	ORA	A				; RESET CARRY FLAG
	POP	D
	RET	
	
4$:	; 	CURRENT LINE == LINE SEARCHED FOR
	STC					; SET CARRY
	POP	D
	RET	
	
5$:	; 	NOT THIS ONE, GO TO NEXT LINE
	MOV	E,M				; LOAD SIZE IN E
	MVI	D,0				; DE = SIZE
	
	DAD	D				; HL = NEXT LINE
	
	JMP	1$				; LOOP

;*********************************************************
;* PRG_INSERT:	INSERTS LINE IN CURRENT PROGRAM
;*		IN: LINE NO TO INSERT IN BC
;*		IN: PTR TO LINE IN HL
;*		IN: LENGTH OF LINE IN E
;*		(REPLACE IF ALREADY EXISTS)
PRG_INSERT::
	PUSH	PSW				; PUSH LENGTH
	PUSH	H				; PUSH PTR TO NEW LINE
	PUSH	B				; PUSH LINE NUMBER

	ADI	3				; LENGTH = LENGTH + 3
	PUSH	PSW				; KEEP LENGTH
	
	STA	INT_ACC0			; STORE L+3 IN INT_ACC0
	MVI	A,0
	STA	INT_ACC0+1
	
	CALL	PRG_FIND			; FIND LINE
	JNC	NOREMOVE
	
	; LINE EXISTS - REMOVE IT
;	CALL	PRG_REMOVEPTR
	
NOREMOVE: 	
	; ADDRESS TO INSERT AT IS IN HL
	SHLD	INT_ACC1			; PUT ADDR IN INT_ACC1
	
	LXI	H,INT_ACC1
	CALL	INT_ADD				; INT_ACC0 = ADDR+LENGTH+3
	
	LHLD	INT_ACC0			; READ BACK RESULT IN HL
	XCHG					; SWAP WITH DE
	
	LHLD	PRG_HIPTR			; TOP OF PROGRAM MEMORY IN HL
	SHLD	INT_ACC0
	
	LXI	H,INT_ACC1
	CALL	INT_SUB				; INT_ACC0 = HIPTR - ADDR
	
	LDA	INT_ACC0			; READ LO BYTE IN ACC
	MOV	C,A				; COPY TO C
	LDA	INT_ACC0+1			; READ HI BYTE IN ACC
	MOV	B,A				; COPY TO B
	
	LHLD	INT_ACC1			; READ ADDRESS IN HL
	XCHG					; SWAP HL<->DE
	
	CALL	C_MEMCPYF			; MOVE PROGRAM UP TO MAKE
						; SPACE FOR NEW LINE

	;
	XCHG					; ADDRESS IN HL
						
	POP	PSW				; GET BACK LENGTH+3
	MOV	M,A				; PUT AT ADDR
	INX	H				; HL++
	
	POP	B				; GET BACK LINE NUMBER
	
	MOV	M,C				; LO BYTE
	INX	H
	MOV	M,B				; HI BYTE
	INX	H
	
	POP	D				; RESTORE NEW LINE PTR
	POP	PSW				; RESTORE LENGTH
	
	MOV	C,A				; COPY TO BC
	MVI	B,0
	CALL	C_MEMCPY			; COPY LINE CONTENTS
	
	MOV	A,C				; GET LENGTH
	ADI	3				; ADD 3
	MOV	C,A				; PUT BACK IN C
	
	LHLD	PRG_HIPTR			; GET HI PTR
	DAD	B				; ADD LENGTH+3
	SHLD	PRG_HIPTR			; BACK IN VAR
	SHLD	VAR_LOPTR
	SHLD	VAR_HIPTR
	
	RET

;*********************************************************
;* PRG_REMOVE:	REMOVES LINE FROM PROGRAM
PRG_REMOVE::
	RET

;*********************************************************
;* PRG_RUN:	RUNS CURRENT PROGRAM
PRG_RUN::
	RET

;*********************************************************
;* PRG_GOTO:	GO TO SPECIFIED LINE
PRG_GOTO::
	RET

;*********************************************************
;* PRG_GOSUB:	GO TO SPECIFIED LINE, PUSH CURRENT ADDRESS
;*		ON THE STACK FOR RETURN
PRG_GOSUB::
	RET

;*********************************************************
;* PRG_RETURN:	POPS RETURN ADDRESS FROM THE STACK, 
;*		CONTINUE EXECUTION
PRG_RETURN::
	RET


;*********************************************************
;* PRG_END:	ENDS CURRENT PROGRAM
PRG_END::
	MVI	A,255
	STA	PRG_ISEND
	RET

;*********************************************************
;* PRG_STOP:	STOPS CURRENT PROGRAM, SAVES POSITION
;*		TO CONTINUE LATER
PRG_STOP::
	RET

;*********************************************************
;* PRG_CONTINUE:	CONTINUE RUNNING PROGRAM
PRG_CONTINUE::
	RET

;*********************************************************
;* PRG_FOR:	FOR LOOP
PRG_FOR::
	RET

;*********************************************************
;* PRG_NEXT:	END OF FOR LOOP
PRG_NEXT::
	RET


;*********************************************************
;* RAM VARIABLES
;*********************************************************

.area	DATA	(REL,CON)

PRG_LOPTR::		.ds	2		; BOTTOM OF PROGRAM MEMORY
PRG_HIPTR::		.ds	2		; TOP OF PROGRAM MEMORY


PRG_CURRLINE:		.ds	2		; CURRENT LINE NUMBER

PRG_NEWLINEPTR:		.ds	2		; 
PRG_CURRLINEPTR:	.ds	2		; 
PRG_CURRPOSPTR:		.ds	2		; 
PRG_NEXTRETURNPOINTPTR:	.ds	2		; 
PRG_NEXTCURRLINEPTR:	.ds	2		; 

PRG_INIF:		.ds	1		; 
PRG_ISEND:		.ds	1		; 
PRG_ISNEXT:		.ds	1		; 
