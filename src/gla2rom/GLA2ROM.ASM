        PAGE 59,132
        TITLE GLA2ROM
_TEXT   SEGMENT
        ASSUME CS:_TEXT,DS:_TEXT,ES:_TEXT,SS:_TEXT
        ORG     100H

;============================================================================;
; Convert a MASM/LINK generated EXE to 8K-aligned ROM image.
;----------------------------------------------------------------------------;
; Usage:
;	GLA2ROM GLABIOS.EXE GLABIOS.ROM
;
; Switches:
; 	GLA2ROM /[1-8] BIOS.EXE BIOS.ROM
;
;	/[1-8] - Duplicate 8K ROM this number of times
;			8K = 1 (default)
;			16K = 2
;			32K = 4
;			64K = 8
;----------------------------------------------------------------------------;

VER_NAME	EQU	'GLa2ROM'
VER_NUM	EQU	'1.0'
COPY_YEAR	EQU	'2022'

QUIET_MODE	EQU	0			; display no output during build

;----------------------------------------------------------------------------;
; Load ROM file FN into DEST
;----------------------------------------------------------------------------;
FOPEN	MACRO	FN
		;LOCAL FOPEN, FREAD, FCLOSE, FERR
	MOV	AX, 3D00H 			; DOS open file for read (mode 0)
	MOV	DX, FN			; DX = ASCIIZ file name and path
	INT	21H 				; AX = file handle
	;JC	FERR 				; handle error

		ENDM

;----------------------------------------------------------------------------;
; Read ROM file data
;----------------------------------------------------------------------------;
; Input BX = file handle
;
; CF if error
FREAD MACRO DEST
	;MOV	BX, AX			; BX = DOS file handle
	MOV	CX, SIZE DEST		; read chars
	LEA	DX, DEST 			; load into CHAR
	MOV	AH, 3FH 			; DOS read from file
	INT	21H

		ENDM

;----------------------------------------------------------------------------;
; Close ROM file handle
;----------------------------------------------------------------------------;
; Input BX = file handle
;
FCLOSE MACRO
 	MOV	AH, 3EH			; close file
 	INT	21H
 		ENDM

;----------------------------------------------------------------------------;
; Seek file pointer
;----------------------------------------------------------------------------;
; Input:
; 	Start: AL = 0: beginning, 1: current, 2: end
;	BX = file handle
; 	CX:DX = Position
;
FSEEK MACRO
 	MOV	AH, 42H			; close file
 	INT	21H
 		ENDM

;----------------------------------------------------------------------------;
; Write ROM file data
;----------------------------------------------------------------------------;
; Input:
;	FN = outpu file name
; 	DI = times to write/repeat
; Output:
;	DX = bytes written
;
SAVEROM	MACRO	FN, DEST
		LOCAL FOPEN, FWRITE, FCLOSE, FERR
FOPEN:
	MOV	AX, 3C00H 			; DOS Create or Truncate File
	MOV	DX, FN			; DX = ASCIIZ file name and path
	INT	21H 				; AX = file handle
	JC	FERR 				; handle error
FWRITE:
	MOV	BX, AX			; BX = DOS file handle
	XOR	BP, BP
	MOV	CX, SIZE DEST		; write # of chars
	LEA	DX, DEST 			; save to DEST
FWRITE_LOOP:
	MOV	AH, 40H 			; DOS write to file
	INT	21H
	ADD	BP, AX
	DEC	DI
	JNZ	FWRITE_LOOP
	MOV	DX, BP			; DX = bytes written
	JC	FCLOSE			; handle error (maybe)
FCLOSE:
 	MOV	AH, 3EH			; close file
 	INT	21H
 	XCHG	AX, DX
FERR:
		ENDM

;----------------------------------------------------------------------------;
; EXE file header structure
;----------------------------------------------------------------------------;
MZEXE STRUC
MZ		DB 	2 DUP(?) 		; 'MZ'
PGSZ_L	DW	?			; Number of bytes in last 512-byte page
PGSZ		DW	?			; Total number of 512-byte pages
RELO		DW	?			; Number of relocation entries
HDRSZ		DW	?			; Header size in paragraphs
		DW	?			; Minimum paragraphs of memory
		DW	?			; Maximum number of paragraphs
		DW	?			; Initial SS relative to start
		DW	?			; Initial SP
		DW	?			; Checksum (or 0) of executable
		DD	?			; CS:IP relative to start of executable
		DW	?			; Offset of relocation table;
		DW	?			; Overlay number (0h = main program)
;		DB	1E4H DUP(?)
MZEXE	ENDS

;----------------------------------------------------------------------------;
; 8K BIOS segment
;----------------------------------------------------------------------------;
BIOS8	STRUC
CODEDAT	DB	1FFFH DUP(?)
CHKSUM	DB	?			; last byte is for checksum
BIOS8	ENDS

START:
	MOV	DX, OFFSET BANNER
	CALL	OUT_STR

	XOR	AX, AX
	XOR	BX, BX
	XOR	CX, CX
	XOR	DX, DX
	XOR	SI, SI
	XOR	DI, DI

	CALL	PARSE_CMD_LINE		; BX = input file, SI = output file
	PUSHF					; save command line return flags
F_OKAY:
	MOV	EXEFN, BX
	MOV	ROMFN, SI
	XOR	DH, DH
	MOV	OUT_REP, DX
	PUSH	DX				; save repeat count for later display
	PUSH	SI

	MOV	DX, OFFSET S_IN_FN	; display "Input: " string
	CALL	OUT_STR

	MOV	SI, BX			; display input file name from cmd line
	CALL	OUTLN_SZ

	MOV	DX, OFFSET S_OUT_FN	; display "Output: " string
	CALL	OUT_STR

	POP	SI				; display output file name
	CALL	OUTLN_SZ

	MOV	DX, OFFSET S_DUP
	CALL	OUT_STR

	POP	AX				; display 8K block repeat count
	CALL	NIB_HEX
	CALL	OUT_CRLF

;----------------------------------------------------------------------------;
; Verify command line was valid 
;
	POPF					; restore command line parsing error flags
	JNC	NO_CMD_ERR			; jump and exit if command line invalid

;----------------------------------------------------------------------------;
; Command Line Error has occurred
;----------------------------------------------------------------------------;
	MOV	DX, OFFSET CMD_ERR
	JMP	OUT_STR			; display error and return to DOS

;----------------------------------------------------------------------------;
; Open input file
;
NO_CMD_ERR:
	FOPEN EXEFN				; open input file
	JC	F_ERROR			; error loading file

;----------------------------------------------------------------------------;
; Read EXE file header
;
	MOV	BX, AX			; BX = file handle
	FREAD GHDR				; read header
	JC	F_ERROR			; error reading file header

;----------------------------------------------------------------------------;
; Calculate input file offset to extract
;
	MOV	DX, GHDR.HDRSZ		; DX = EXE header size (in paragraphs)
	MOV	CL, 4				; convert to bytes
	SHL	DX, CL

	MOV	AL, 0				; seek from start position
	XOR	CX, CX			; high word of seek length
	ADD	DX, 2000H * (8 - 1)	; add offset of last 8K chunk of data
	FSEEK
	JC	F_ERROR			; error seeking file

;----------------------------------------------------------------------------;
; Read ROM code into memory
;
	FREAD BCODE				; DX = pointer to file data buffer
	JC	F_ERROR			; error reading file code
	FCLOSE				; close input EXE file

;----------------------------------------------------------------------------;
; Calculate checksum
;
	MOV	SI, DX			; SI = BCODE buffer
	MOV	CX, SIZE BCODE/2		; CX = code size in WORDs
	CALL	CHECKSUM_ROM		; AL = calculated checksum
	MOV	BCODE.CHKSUM, AL		; write checksum to code buffer

;----------------------------------------------------------------------------;
; Write output ROM code to file
;
	MOV	DI, OUT_REP			; DI = repeat count
	SAVEROM ROMFN, BCODE		; write code to output file
	JC	F_ERROR

;----------------------------------------------------------------------------;
; Display bytes written and exit
;
			IF QUIET_MODE NE 1
	MOV	DX, OFFSET OUT_STATUS
	CALL	OUT_STR
	CALL	WORD_HEX
	JMP	OUT_CRLF			; display new line and return to DOS
			ELSE
	RET					; return to DOS
			ENDIF

;----------------------------------------------------------------------------;
; File operation error has occurred
;----------------------------------------------------------------------------;
; Input: AX = error code
;
F_ERROR:
	MOV	DX, OFFSET FILE_ERR
	CALL	OUT_STR
	JMP	WORD_HEX			; display error code and return to DOS


;----------------------------------------------------------------------------;
; Calculate 8 bit checksum of ROM image
;----------------------------------------------------------------------------;
; Input:
;  DS:SI = Input Data
;  CX = Size in WORDs
;
; Output:
;  AL = checksum needed to make 0
;----------------------------------------------------------------------------;
CHECKSUM_ROM PROC
	XOR	BX, BX			; BL = accumulator for sum
CHECKSUM:
	LODSW					; next two bytes into AL and AH
	ADD	BL, AL
	ADD	BL, AH
	LOOP	CHECKSUM 			; loop through entire ROM
	XCHG	AX, BX			; result into AL
	NEG	AL				; calculate remaining value needed
	RET
CHECKSUM_ROM ENDP

;----------------------------------------------------------------------------;
; Parse Command Line
;----------------------------------------------------------------------------;
; ZF if no input?
; Output:
; 	BX = input file name
;	SI = output file name
;	CF if error
; 
; GLA2ROM /1 BIOS.EXE BIOS.ROM
; 
;  Parse command line for:
;	/[1-8]			- Duplicate ROM in output this number of times
;					- default 1
;----------------------------------------------------------------------------;
PARSE_CMD_LINE PROC
	MOV	SI, 80H 				; DOS PSP offset
	LODSB 					; command line length into AL
	TEST	AL, AL 				; is zero length?
	JZ	CMD_PARSE_FN_ERR 			; if no command line, exit
	CBW						; AH = 0
	MOV	DL, 1					; number of times to duplicate output
	XCHG	AX, CX				; CX = length
	INC	CX                       	; make sure last char is never a match
CMD_LOOP:
	LODSB						; next char in AL
	CMP	AL, '/'
	JL	CMD_LOOP				; is space or other?
	JNZ	CMD_NOT_SLASH
	LODSB
	DEC	CX
	DEC	CX
	SUB	AL, '0'
	JLE	CMD_IN_FN				; <= 0, not valid
	CMP	AL, 8					; is > 8?
	JG	CMD_IN_FN
	XCHG	AX, DX				; DL = duplicate count
	INC	SI
CMD_NOT_SLASH:
	DEC	SI
CMD_IN_FN:
	MOV	DI, SI
	CALL	CMD_PARSE_FN
	JCXZ	CMD_PARSE_FN_ERR			; reached end already? Exit with error
	MOV	BX, SI				; BX = beginning of input file
CMD_PARSE_FN:
	MOV	AL, ' '
	REPZ	SCASB					; trim space
	JCXZ	CMD_PARSE_FN_ERR			; reached end already? Exit with error
	DEC	DI
	MOV	SI, DI				; SI = beginning of next file
	REPNZ	SCASB					; search until next space
	JCXZ	CMD_PARSE_FN_END			; is end of string?
	;JZ	CMD_PARSE_FN_END			; no match?
CMD_PARSE_FN_END_1:
	PUSHF
	DEC	DI
	POPF
CMD_PARSE_FN_END:
	MOV	AL, 0					; null terminate string
	STOSB
	CLC
	JZ	CMD_LINE_DONE
	JCXZ	CMD_LINE_DONE
CMD_PARSE_FN_ERR:
	STC
CMD_LINE_DONE:
	RET
PARSE_CMD_LINE ENDP

;--------------------------------------------------------------------------
; Write WORD AX as HEX to console
;--------------------------------------------------------------------------
WORD_HEX PROC
	PUSH	AX 				; save AX
	MOV	AL, AH 			; move high byte into low byte
	CALL	BYTE_HEX 			; write byte as HEX to console
	POP	AX 				; restore AX

;--------------------------------------------------------------------------
; Write BYTE AL as HEX to console
;--------------------------------------------------------------------------
BYTE_HEX PROC
	PUSH	AX 				; save AL
	SHR	AL, 1				; move high nibble to low nibble
	SHR	AL, 1				; move high nibble to low nibble
	SHR	AL, 1				; move high nibble to low nibble
	SHR	AL, 1				; move high nibble to low nibble
	CALL	NIB_HEX 			; write low nibble of AL as HEX to console
	POP	AX 				; restore AL

;--------------------------------------------------------------------------
; Write low nibble of AL as HEX to console
;--------------------------------------------------------------------------
NIB_HEX PROC
	AND	AL, 0FH 			; isolate low nibble
	CMP	AL, 10 			; CF if <= 9
	SBB	AL, 069H 			; convert to hex
	DAS

;--------------------------------------------------------------------------
; Write char in AL to console
;--------------------------------------------------------------------------	
OUT_CHAR PROC
		IF QUIET_MODE NE 1
	PUSH	AX
	MOV	AH, 0EH			; Write AL to screen tty mode
	INT	10H				; send to video
	POP	AX
		ENDIF
	RET

OUT_CHAR ENDP
NIB_HEX ENDP
BYTE_HEX ENDP
WORD_HEX ENDP

;----------------------------------------------------------------------------;
; Display a zero-terminated string
;----------------------------------------------------------------------------;
; Input: DS:SI = String
;----------------------------------------------------------------------------;
OUT_SZ PROC
		IF QUIET_MODE NE 1
	PUSH	AX
	MOV	AH, 0EH			; TTY output
OUT_SZ_LOOP:
	LODSB
	TEST	AL, AL			; is zero terminator?
	JZ	OUT_SZ_DONE			; if so, exit
	INT	10H
	JMP	SHORT OUT_SZ_LOOP
OUT_SZ_DONE:
	POP	AX
		ENDIF
	RET
OUT_SZ ENDP

;----------------------------------------------------------------------------;
; Display a zero-terminated string with CRLF
;----------------------------------------------------------------------------;
OUTLN_SZ PROC
	CALL	OUT_SZ
OUTLN_SZ ENDP

;----------------------------------------------------------------------------;
; Write a CRLF string to console
;----------------------------------------------------------------------------;
OUT_CRLF PROC
	PUSH	DX
	MOV	DX, OFFSET CRLF
	CALL	OUT_STR
	POP	DX
	RET
OUT_CRLF ENDP

;----------------------------------------------------------------------------;
; Display a DOS-terminated ('$') string
;----------------------------------------------------------------------------;
OUT_STR PROC
		IF QUIET_MODE NE 1
	PUSH	AX
	MOV	AH, 9
	INT	21H
	POP	AX
		ENDIF
	RET
OUT_STR ENDP

;----------------------------------------------------------------------------;
; Data, Strings and Things
;----------------------------------------------------------------------------;

BANNER	DB	VER_NAME
		DB	' [', 03H, '] '
		DB	VER_NUM
		DB	0DH, 0AH

COPYRIGHT	DB	'(C) ', COPY_YEAR, ' '
		DB	'640KB Released under GPLv3'
		DB	0DH, 0AH, 0AH
		DB	'$'

OUT_STATUS	DB	'Bytes Written: $'

FILE_ERR	DB	07H, 'File Error: ', 0DH, 0AH, '$'
CMD_ERR	DB	07H, 'Command Line Error.'
CRLF		DB	0DH, 0AH, '$'

S_IN_FN	DB	'Input  : ', '$'
S_OUT_FN	DB	'Output : ', '$'
S_DUP		DB	'Repeat : ', '$'

;----------------------------------------------------------------------------;
; Allocate data in code space for simplicity...
;

EXEFN		DW	?			; input file name
ROMFN		DW	?			; output file name
OUT_REP	DW	?			; output repeats

GHDR		MZEXE <>			; EXE file header record
BCODE		BIOS8 <>			; 8K BIOS code

_TEXT ENDS
END START
