.module 	program
.title 		Program module

.include	'..\common\common.def'
.include	'..\error\error.def'
.include	'..\variables\variable.def'

.area	_CODE

;*********************************************************
;* PRG_INIT:	INITIALIZES PROGRAM MODULE
PRG_INIT::
	MVI	A,0
	LXI	H,0				; CLEAR PTRS
	
	SHLD	PRG_NEWLINE
	SHLD	PRG_CURRLINE
	SHLD	PRG_CURRPOS
	
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
	RET

;*********************************************************
;* PRG_INSERT:	INSERTS LINE IN CURRENT PROGRAM
;*		(REPLACE IF ALREADY EXISTS)
PRG_INSERT::
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

PRG_NEWLINE:		.ds	2		; 
PRG_CURRLINE:		.ds	2		; 
PRG_CURRPOS:		.ds	2		; 
PRG_NEXTRETURNPOINT:	.ds	2		; 
PRG_NEXTCURRLINE:	.ds	2		; 

PRG_INIF:		.ds	1		; 
PRG_ISEND:		.ds	1		; 
PRG_ISNEXT:		.ds	1		; 
