	PAGE	 	59,132
	TITLE		GLaBIOS

;----------------------------------------------------------------------------;
; GLaBIOS (General Libraries and Basic Input Output System)
;
; An scratch-built, open-source 8088 PC/clone BIOS alternative.
;
; Copyright (c) 2022, 640KB and contributors
;
;----------------------------------------------------------------------------;
;
; This program is free software: you can redistribute it and/or modify it under the terms 
; of the GNU General Public License as published by the Free Software Foundation, either 
; version 3 of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
; See the GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along with this program. 
; If not, see <https://www.gnu.org/licenses/>.
;
;----------------------------------------------------------------------------;
; References and Credits:
; 
;  https://stanislavs.org/helppc/
;  http://www.minuszerodegrees.net/
;  https://www.felixcloutier.com/x86/
;  https://sites.google.com/site/pcdosretro/ (now offline)
;
;  "Programmer's Guide to the IBM(R) PC", Peter Norton
;  "System BIOS for IBM(R) PC/XT(TM)/AT(R) Computers and Compatibles",
;	Phoenix Technologies Ltd.
;  "Programmer's Guide to PC Video Systems", Second Edition, Wilton
;
;  Font bitmaps by "VileR", (CC BY-SA 4.0)
;  https://int10h.org/oldschool-pc-fonts/readme/#legal_stuff
;
;  @Raffzahn, Contributor, Mentor and Meckerhut.
;
;  https://github.com/640-KB/GLaBIOS#further-credits-to
;----------------------------------------------------------------------------;
; BUILD NOTES:
;
; Build using MASM 5.0.
;	Why? MASM and MASM syntax is what I have used and is what I am most 
;	familiar in assembly language. Perhaps it also provides some sense of 
;	historical authenticity [citation needed]?
;
; Code style:
;	GLaBIOS uses all UPPERCASE mnemonics because 1) it was the way I 
;	originally learned assembly language 2) it's what's used in MASM 5 
;	documentation and manuals 3) it would have been an accepted practice in
;	the era in when a PC BIOS clone was written. We're gonna party like it's
;	1985.
;
; Code Formatting
; 	- Tab Size: 6 spaces. Indented with TAB characters.
;
; Inline Documentation
; 	The "Things you must/should do" sections are given as high-level 
;	implementation requirements, similar to what a "clean room" engineer 
;	might be given (these section headings were inspired by sircabirus.com
;	strategy guides, since for whatever reason that kept coming to mind
;	every time I went to write one of those).
;----------------------------------------------------------------------------;
; Build Instructions:
;
;  MAKE.BAT
;
; or
;
;  MASM GLABIOS;
;  LINK GLABIOS;
;  GLA2ROM GLABIOS.EXE GLABIOS.ROM		; Build 8K ROM
;
; or
;
;  GLA2ROM /4 GLABIOS.EXE GLABIOS.ROM	; Build 32K ROM (8K duplicated 4x)
;
; MASM Build Options:
;  /DVER_DATE="02/22/22"			; Must be MM/DD/YY format
;  /DARCH_TYPE="X"				; P, X, Y or T (see ARCH_* below)
;  /DCPU_TYPE="8"					; 8 or V (see CPU_* below)
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Build Target Architecture equates (do not edit these)
;
ARCH_5150		EQU	'P'			; 5150
ARCH_5160		EQU	'X'			; 5160 v1
ARCH_5160v2		EQU	'Y'			; 5160 v2/3
ARCH_TURBO		EQU	'T'			; Turbo or clone

;
; CPU Instruction Set Target
;
CPU_8088		EQU	'8'			; 808x compatible
CPU_V20		EQU	'V'			; V20 only

;
; Boot to Turbo or Normal Speed
;
BOOT_TURBO		EQU	'T'
BOOT_NORMAL		EQU	'N'

;
; Turbo Switch Type
;
TURBO_STD		EQU	1			; standard PPI B, 04h
TURBO_REV		EQU	2			; reversed PPI B, 04h
TURBO_90H		EQU	3			; ST-xx/UNIQUE Port 90h

;----------------------------------------------------------------------------;
; BEGIN Configurable Build Options
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Default Target Architecture Settings
;
	IFNDEF ARCH_TYPE
;ARCH_TYPE		EQU	ARCH_5150		; PC 5150
;ARCH_TYPE		EQU	ARCH_5160		; PC 5160 (recommended)
;ARCH_TYPE		EQU	ARCH_5160v2		; PC 5160v2 (not recommended)
ARCH_TYPE		EQU	ARCH_TURBO		; Turbo (clock >= 4.77MHz)
	ENDIF

;----------------------------------------------------------------------------;
; Default CPU Instruction Set Target
;
	IFNDEF CPU_TYPE
CPU_TYPE		EQU	CPU_8088		; CPU_8088 or CPU_V20
;CPU_TYPE		EQU	CPU_V20		; use V20-only instructions
	ENDIF

;----------------------------------------------------------------------------;
; Turbo Type
;
; Some motherboards boot in Normal mode by default and the BIOS may or may not
; switch to Turbo speed on boot. Other motherboards invert this behavior where
; it appears reversed to the BIOS. Use these options to customize for your
; motheboard.
;
	IFNDEF TURBO_TYPE
;TURBO_TYPE		=	TURBO_STD	; standard PPI 61h (1=turbo, 0=normal)
TURBO_TYPE		=	TURBO_REV	; reversed PPI 61h (1=normal, 0=turbo)
;TURBO_TYPE		=	TURBO_90H	; ST-xx/UNIQUE Port 90h
	ENDIF

;----------------------------------------------------------------------------;
; Additional Build-time Support
;
BASIC_ROM		=	1		; BASIC ROM support at 0F600h

;----------------------------------------------------------------------------;
; CGA Snow Removal Method
;
CGA_SNOW_REMOVE	=	3		; 0: Snow, Normal Flashing, Fastest
						; 1: Less Snow, Some Flashing, Medium Fast
						; 2: No Snow, Moderate Flashing, Fast
						; 3: No Snow, More Flashing, Quite Fast

;----------------------------------------------------------------------------;
; Personality Traits
;
POST_GLADOS		=	0		; say "Starting GLaDOS..." on boot
POST_CLS		=	0		; clear screen after POST
POST_SHOW_VER	=	3		; POST screen verbosity (0-3)
POST_VIDEO_TYPE	=	1		; show the video adapter type on POST

;----------------------------------------------------------------------------;
; Enable/Disable POST tests - Not all tests can be enabled due to 8K ROM space
;
POST_TEST_INST	=	0		; POST CPU Instruction/Flag Test
POST_TEST_DMA	=	1		; POST DMA Register Test
POST_TEST_PIT_1	=	1		; POST Timer Channel 1 Test
POST_TEST_PIC_REG	=	1		; POST PIC Register Test
POST_TEST_PIC_INT	=	1		; POST PIC Interrupt Test
POST_TEST_CHK_ROM	=	1		; POST Checksum ROM

;----------------------------------------------------------------------------;
; Advanced Options (may void your warranty)
;
MAX_RAM 		=	640		; Max detectable RAM (in KB)
DRAM_REFRESH	=	1		; 1: Use standard DMA DRAM refresh
						; 0: Disable refresh (use only with SRAM!)
OPT_ROM_END		=	0FE00H	; Option ROM scan ending address
FDC_HTL_WAIT	=	1		; Halt CPU during FD access


;----------------------------------------------------------------------------;
; END Configurable Build Options
;----------------------------------------------------------------------------;


;----------------------------------------------------------------------------;
; BIOS Product Info
;
VER_NAME		EQU	'GLaBIOS'
	IFNDEF VER_NUM
VER_NUM		EQU	'0.1.7'		; (max 6 chars)
	ENDIF
	IFNDEF VER_DATE
VER_DATE		EQU	'10/17/22' 		; must be MM/DD/YY format
	ENDIF
	IFNDEF COPY_YEAR
COPY_YEAR		EQU	'2022'		; can be set at build time
	ENDIF
	IFNDEF VER_BLD
VER_BLD		EQU	'0000'
	ENDIF

;----------------------------------------------------------------------------;
; Boot to normal or turbo speed (if supported)
;
	IF ARCH_TYPE EQ ARCH_TURBO
BOOT_SPEED		EQU	BOOT_TURBO
	ELSE
BOOT_SPEED		EQU	BOOT_NORMAL
	ENDIF

;----------------------------------------------------------------------------;
; Configuration for ST-xx/90h boards
;
	IF TURBO_TYPE EQ TURBO_90H
BASIC_ROM		= 	0			; remove for space reasons
FDC_HTL_WAIT	=	0			; seems to cause issues on ST-xx
	ENDIF

;----------------------------------------------------------------------------;
; Enable 186 instructions if V20
;
	IF CPU_TYPE EQ CPU_V20
.186
	ENDIF

;----------------------------------------------------------------------------;
; BIOS ID Byte
; https://stanislavs.org/helppc/id_bytes.html
;
; NOTE: DOS may re-vector some interrupts or attempt bug workarounds 
; depending on this byte.
;
	IF ARCH_TYPE EQ ARCH_5150
ARCH_ID		EQU	0FFH			; 0xFF=5150
	ELSE
	IF ARCH_TYPE EQ ARCH_5160v2
ARCH_ID		EQU	0FBH			; 0xFB=XT v2/v3
	ELSE
ARCH_ID		EQU	0FEH			; 0xFE=XT v1
	ENDIF
	ENDIF

;----------------------------------------------------------------------------;
; PC ISA (Instruction Set Architecture) I/O Port Addresses
;----------------------------------------------------------------------------;

; 8237A DMA Controller
DMA_0_A		EQU	00H 			; W   Start Address Register channel 0
DMA_0_C		EQU	01H			; W   Count Register channel 0
DMA_1_A		EQU	02H			; W   Start Address Register channel 1
DMA_1_C		EQU	03H			; W   Count Register channel 1
DMA_2_A		EQU	04H			; W   Start Address Register channel 2
DMA_2_C		EQU	05H			; W   Count Register channel 2
DMA_3_A		EQU	06H			; W   Start Address Register channel 3
DMA_3_C		EQU	07H			; W   Count Register channel 3
DMA_CMD		EQU	08H			; RW  Status / Command Register
DMA_REQ		EQU	09H			; W   Request Register
DMA_MASK		EQU	0AH 			; W   Single Channel Mask Register
DMA_MODE		EQU	0BH 			; W   Mode Register
DMA_FF		EQU	0CH 			; W   Flip-Flop Reset Register
DMA_RESET		EQU	0DH 			; W   Master Reset Register (Mask bits ON)
DMA_MASKR		EQU	0EH 			; W   Mask Reset Register (Mask bits OFF)
DMA_MMASK		EQU	0FH 			; RW  MultiChannel Mask Register

; DMA Page Registers (74LS670)
DMA_P_C0		EQU	87H			; DMA Channel (unused on PC)
DMA_P_C1		EQU	83H			; DMA Channel 0 and 1
DMA_P_C2		EQU	81H			; DMA Channel 2
DMA_P_C3		EQU	82H			; DMA Channel 3

; 8259 PIC Interrupt Controller
INT_P0		EQU	20H 			; Port 0
INT_P1		EQU	21H 			; Port 1
INT_EOI		EQU	0100000B 		; OCW2 - Non-specific EOI command

; 8253 PIT Timer
PIT_CH0		EQU	40H			; Timer Channel/Counter 0
PIT_CH1		EQU	41H			; Timer Channel/Counter 1
PIT_CH2		EQU	42H			; Timer Channel/Counter 2 - Speaker
PIT_CTRL		EQU	43H			; Timer Control Word

; 8255 PPI Peripheral Interface
PPI_A			EQU	60H			; PPI (8255) Port A IN  - Keyboard input
PPI_B			EQU	61H			; PPI (8255) Port B OUT - Speaker, Switch selection, Misc
PPI_C			EQU	62H			; PPI (8255) Port C IN  - Switches
PPI_CW		EQU	63H			; PPI (8255) Port Control Word

; POST TEST card I/O
POST_CARD_PORT	EQU	80H			; can be 60H, 80H, 300H, 313H

; 90H ST/UNIQUE Turbo Control
TURBO_CTRL_90H	EQU	90H			; Write 2 for Turbo, 3 for Normal

; NMI flip/flop
NMI_R0		EQU	0A0H			; CPU NMI Register

; Joystick / Game Port
GAME_CTRL		EQU	0201H			; Game Port

; Hard Disk Controller
HDC_READ		EQU	0320H			; Read from/Write to controller
HDC_CTRL		EQU	0321H			; Read: Controller Status, Write: controller reset
HDC_PULSE		EQU	0322H			; Write: generate controller select pulse
HDC_DMA		EQU	0323H			; Write: Pattern to DMA and interrupt mask register
HDC_STAT		EQU	0324H			; disk attention/status

; Video 6845 CRT Controller
MDA_CTRL		EQU	03B8H			; MDA CRT Control Port 1
MDA_STAT		EQU	03BAH			; MDA Status Register
CGA_CTRL		EQU	03D8H			; CGA Mode Select Register
CGA_STAT		EQU	03DAH			; CGA Status Register

; Serial (COM) ports
COM1_DATA		EQU	03F8H 		; 03F8H: TX/RX Buffer, Divisor LSB (RW)
COM1_IER		EQU	COM1_DATA+1		; 03F9H: Interrupt Enable Register, Divisor MSB (RW)
COM1_IIR		EQU	COM1_DATA+2		; 03FAH: Interrupt Identification Register (R)
COM1_LCR		EQU	COM1_DATA+3		; 03FBH: Line Control Register (RW)
COM1_MCR		EQU	COM1_DATA+4		; 03FCH: Modem Control Register (RW)
COM1_LSR		EQU	COM1_DATA+5		; 03FDH: Line Status Register (R)
COM1_MSR		EQU	COM1_DATA+6		; 03FEH: Modem Status Register (R)
COM1_SPR		EQU	COM1_DATA+7		; 03FFH: Scratch Pad Register (RW)
COM2_DATA		EQU	COM1_DATA-100H	; 02F8H: TX/RX Buffer, Divisor LSB (RW)
COM3_DATA		EQU	COM1_DATA-10H	; 03E8H: TX/RX Buffer, Divisor LSB (RW)
COM4_DATA		EQU	COM2_DATA-10H	; 02E8H: TX/RX Buffer, Divisor LSB (RW)

; BDA timeouts
LPT_TO		EQU	14H			; LPT default timeout
COM_TO		EQU	01H			; COM default timeout

;----------------------------------------------------------------------------;
; FDC (NEC PD765x) Controller 
;

; Floppy Disk Controller Ports
FDC_A_STAT		EQU	03F0H			; Diskette controller status A
FDC_B_STAT		EQU	03F1H			; Diskette controller status B
FDC_CTRL		EQU	03F2H			; FD controller control port
FDC_STAT		EQU	03F4H			; FD controller status register
FDC_DATA		EQU	03F5H			; data register (write 1-9 byte command, see INT 13)

; FDC Commands
FDC_CMD_READTK	EQU	00000010B		; 02H: Read Track (Diagnostic)
FDC_CMD_SPEC 	EQU	00000011B		; 03H: Specify Step & Head Load
FDC_CMD_STATUS 	EQU	00000100B		; 04H: Sense Drive Status
FDC_CMD_WRITE	EQU	00000101B		; 05H: Write Sector
FDC_CMD_READ	EQU	00000110B		; 06H: Read Sector
FDC_CMD_RECAL	EQU	00000111B		; 07H: Recalibrate
FDC_CMD_SENSE	EQU	00001000B		; 08H: Sense Interrupt Status
FDC_CMD_WRDEL	EQU	00001001B		; 09H: Write Deleted Sector
FDC_CMD_SECID	EQU	00001010B		; 0AH: Read Sector ID
FDC_CMD_RDDEL	EQU	00001100B		; 0CH: Read Deleted Sector
FDC_CMD_FMTTK	EQU	00001101B		; 0DH: Format Track
FDC_CMD_SEEK	EQU	00001111B		; 0FH: Seek

FDC_CMD_F_MT	EQU	10000000B		; Multi-Track Flag
FDC_CMD_F_MF	EQU	01000000B		; MFM mode Flag
FDC_CMD_F_SK	EQU	00100000B		; SKip Deleted-data address mark Flag

; BDA INT 13H Status Flags 
; https://stanislavs.org/helppc/int_13-1.html
FDC_ST_OK		EQU	00H			; No error
FDC_ST_BADCMD	EQU	01H			; Bad command passed to driver
FDC_ST_ERR_MARK	EQU	02H			; Address mark not found or bad sector
FDC_ST_ERR_WP	EQU	03H			; Write Protect Error
FDC_ST_ERR_SEC	EQU	04H			; Sector not found
FDC_ST_DMA_OVR	EQU	08H			; DMA overrun
FDC_ST_DMA_64K	EQU 	09H			; DMA access across 64k boundary
FDC_ST_ERR_CRC	EQU	10H			; ECC/CRC error on disk read
FDC_ST_ERR_FDC	EQU	20H			; Controller error
FDC_ST_ERR_SEEK	EQU	40H			; Seek failure
FDC_ST_TIMEOUT	EQU	80H 			; Time out, drive not ready
FDC_ST_SENSE	EQU	0FFH 			; Sense operation failed

; Trivial RAM / data test pattern
RAM_TEST		EQU 	1001010110100101B	; Simple RAM test 095A5H
RAM_TEST_1		EQU 	0111001110011101B	; Alternate RAM test 0739DH
MAGIC_WORD		EQU	0AA55H		; Magic Word used for option ROM, IPL device

; Warm Boot Flag options set in BDA 40:72H
WARM_BOOT		EQU	1234H			; Warm Boot - Skip some POST tests
WARM_BOOT_MEM	EQU	4321H			; Warm Boot - Preserve memory
WARM_BOOT_SUS	EQU	5678H			; Warm Boot - System suspend
WARM_BOOT_TEST	EQU	9ABCH			; Warm Boot - Manufacturer test

VID_DEF_COLS	EQU	80			; standard video mode columns
VID_DEF_ROWS	EQU	24			; standard video mode rows
VID_SP		EQU	' '			; fill byte for blank video RAM char

;----------------------------------------------------------------------------;
; Useful CP-437 Chars
;
CR 			EQU	0DH 			; Carriage return
LF 			EQU	0AH 			; Line feed
BS			EQU	08H			; Backspace ASCII
BELL			EQU	07H			; BELL ASCII
VL			EQU	0B3H			; vertical line
HL			EQU	0C4H			; horizontal line
CURL_TOP		EQU	0F4H
CURL_BOT		EQU	0F5H
BULL			EQU	0F9H			; Bullet operator (medium centered dot)
DOT			EQU	0FAH			; Small middle dot
SQUARE		EQU	0FEH			; Black square (rectangle)
HEART			EQU	03H
NOTE1			EQU	0DH
NOTE2			EQU	0EH
DBLARROW		EQU	01DH

;----------------------------------------------------------------------------;
; PC Text Colors
; https://stanislavs.org/helppc/colors.html
;
BLACK			EQU	0
DARKBLUE		EQU	1
DARKGREEN		EQU	2
CYAN			EQU	3
DARKRED		EQU	4
DARKMAGENTA		EQU	5
BROWN			EQU	6
GRAY			EQU	7
DARKGRAY		EQU	8
BLUE			EQU	9
GREEN			EQU	10
LIGHTCYAN		EQU	11
RED			EQU	12
MAGENTA		EQU	13
YELLOW		EQU	14
WHITE			EQU	15

;----------------------------------------------------------------------------;
; Theme My POST Test!
;----------------------------------------------------------------------------;
POST_THEME		EQU	1			; pick theme from below or roll your own!

		IF POST_THEME EQ 3

; Theme #3 - "Boring"
POST_CLR_TXT	EQU	GRAY			; primary color for text
POST_CLR_VAL1	EQU	GRAY			; value text color
POST_CLR_VAL2	EQU	GRAY			; value text alternate color
POST_CLR_COLD	EQU	BLUE			; COLD color
POST_CLR_WARM	EQU	RED			; WARM color
POST_CLR_GB		EQU	GRAY			; BIOS name in bootup screen
		ELSE
		IF POST_THEME EQ 2

; Theme #2 - "Kinda l33t?"
POST_CLR_TXT	EQU	DARKGRAY
POST_CLR_VAL1	EQU	BLUE
POST_CLR_VAL2	EQU	GREEN
POST_CLR_COLD	EQU	BLUE
POST_CLR_WARM	EQU	RED
POST_CLR_GB		EQU	WHITE
		ELSE

; Theme #1 - "Old skool BBS" (default)
POST_CLR_TXT	EQU	CYAN
POST_CLR_VAL1	EQU	GREEN
POST_CLR_VAL2	EQU	YELLOW
POST_CLR_COLD	EQU	BLUE
POST_CLR_WARM	EQU	DARKRED
POST_CLR_GB		EQU	GRAY
		ENDIF
		ENDIF

;----------------------------------------------------------------------------;
; POST screen column layout options
;
POST_L		EQU	<' [ '>		; left separator string
POST_R		EQU	<' ]'>		; right separator string
L_POST_L		EQU	2			; length of separator

POST_TAB_COL	EQU	32			; horiz tab width for second column
POST_TAB_COL_40	EQU	20			; horiz tab width for second column

POST_COL_LBL_W	EQU	7			; column label width
POST_COL_PAD	EQU	4			; padding (non colored) space between cols

POST_COL_W		EQU	POST_COL_LBL_W-1	; zero-based column index

; column label width plus separator
POST_COL_VT		EQU	POST_COL_LBL_W + L_POST_L

; space between next column
POST_TAB_COL_I	EQU	POST_TAB_COL - POST_COL_LBL_W - L_POST_L - POST_COL_PAD

;----------------------------------------------------------------------------;
; Beepin' Tones
;----------------------------------------------------------------------------;
BEEP_B5		EQU	2418 			; B5
BEEP_C5		EQU	2289			; C5
BEEP_F5		EQU	1710			; F5
BEEP_G5		EQU	1530			; G5
BEEP_A6		EQU	1357			; A6
BEEP_C6		EQU	1140			; C6
BEEP_1K		EQU	1201			; ~1KHz tone

BEEP_DEFAULT	EQU	BEEP_A6		; default beep
BEEP_ERR_HIGH	EQU	BEEP_F5		; perfect fourth apart for
BEEP_ERR_LOW	EQU	BEEP_C5		;  alternating error beeps


;============================================================================;
;
; 			   * * *   S T R U C T S   * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; INT 1E Disk Initialization Parameter Table Vector
;
; https://stanislavs.org/helppc/dbt.html
;----------------------------------------------------------------------------;
DBT	STRUC
D_SRT		DB	? 	; 00 step-rate time SRT (0CH), head unload time HUT (0FH)
D_HLT		DB	? 	; 01 head load time HLT (01H), DMA mode ND (0)
D_SHUT	DB	? 	; 02 timer ticks to wait before disk motor shutoff
D_BPS		DB	? 	; 03 bytes per sector (0=128, 1=256, 2=512, 3=1024)
D_SPT		DB	? 	; 04 sectors per track (last sector number)
D_GAP		DB	? 	; 05 inter-block gap length/gap between sectors
D_SEC		DB	? 	; 06 data length, if sector length not specified
D_FGAP	DB	? 	; 07 gap length between sectors for format
D_FILL	DB	? 	; 08 fill byte for formatted sectors
D_HS		DB	? 	; 09 head settle time in milliseconds
D_START	DB	? 	; 0A motor startup time in eighths of a second
DBT	ENDS

;----------------------------------------------------------------------------;
; INT 1D Video Initialization Parameter Table Vector (VPT)
;
; https://stanislavs.org/helppc/6845.html
;----------------------------------------------------------------------------;
VPT	STRUC
H_TC		DB	?	; 00 - Horiz. total characters
H_CL		DB	?	; 01 - Horiz. displayed characters per line
H_SP		DB	?	; 02 - Horiz. synch position
H_SW		DB	?	; 03 - Horiz. synch width in characters
V_TL		DB	?	; 04 - Vert. total lines
V_SL		DB	?	; 05 - Vert. total adjust (scan lines)
V_DR		DB	?	; 06 - Vert. displayed rows
V_SP		DB	?	; 07 - Vert. synch position (character rows)
IL		DB	?	; 08 - Interlace mode
MSL		DB	?	; 09 - Maximum scan line address
CSL		DB	?	; 0A - Cursor start (scan line)
CEL		DB	?	; 0B - Cursor end (scan line)
SA_H		DB	0	; 0C - Start address (MSB)
SA_L		DB	0	; 0D - Start address (LSB)
CA_H		DB	0	; 0E - Cursor address (MSB) (read/write)
CA_L		DB	0	; 0F - Cursor address (LSB) (read/write)
VPT	ENDS


;============================================================================;
;
; 			   * * *   R E C O R D S   * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; BDA Equipment Flags (40:10H)
;----------------------------------------------------------------------------;
; 00      |			- LPT : # of LPT ports
;   x     |			- X1  :  unused, PS/2 internal modem
;    0    |			- GAM : Game port present
;     000 |			- COM : # of COM ports present
;        0| 		- DMA : DMA (should always be 0)
;         |00	 	- FLP : Floppy drives present (+1) (0=1 drive,1=2,etc)
;         |  00		- VIDM: Video mode (00=EGA/VGA, 01=CGA 40x25, 
; 				-	10=CGA 80x25, 11=MDA 80x25)
;         |    11 	- MBRAM: MB RAM (00=64K, 01=128K, 10=192K, 11=256K+)
;         |      0	- FPU : FPU installed
;         |       1	- IPL : Floppy drive(s) installed (always 1 on 5160)
;----------------------------------------------------------------------------;
EQFLAGS RECORD	LPT:2,X1:1,GAM:1,COM:3,DMA:1,FLP:2,VIDM:2,MBRAM:2,FPU:1,IPL:1

;----------------------------------------------------------------------------;
; GLaBIOS Equipment Flags (40:12H)
;----------------------------------------------------------------------------;
; 76543210
; x 	    |			- TBD		: Reserved
;  x 	    |			- TURBO	: Turbo supported
;   x	    |			- V20		: 1 if V20, 0 if 8088
;    x    |			- RTCMS	: RTC MS5832 detected
;     x   |			- RTCMM	: RTC MM58167AN detected
;      x  |			- RTCRP	: RTC Ricoh RP5C15 detected
;       xx|			- TBD		:
; 84218421
;----------------------------------------------------------------------------;
GFLAGS RECORD	GTBD1:1,TURBO:1,V20:1,RTCMS:1,RTCMM:1,GTBD2:3

;----------------------------------------------------------------------------;
; POST status flags are stored in BP
;----------------------------------------------------------------------------;
; BP:
; 76543210
; x 	    |			- WARM  : Warm Boot flag
;  x 	    |			- PKI   : POST Keyboard Interrupt Received
;   x     |			- PKEY  : Keyboard key stuck
;    x    |			- PFDC  : FDC init failure
;     x   |			- PFSK  : FDC seek test failure
;      x  |			- PDMA  : DMA error
;       x |			- PMEM  : Memory Error
;        x|			- PHDC  : HDC error
;         | xxxxxxxx	- TBD
; 84218421
;----------------------------------------------------------------------------;
PFLAGS RECORD WARM:1,PKI:1,PKEY:1,PFDC:1,PFSK:1,PDMA:1,PMEM:1,PHDC:1,PTBD2:8

;----------------------------------------------------------------------------;
; BDA Keyboard Flags
;----------------------------------------------------------------------------;
; 40:17	Keyboard Flags Byte 1 (Low)
;          84218421
; 	    |7 	    	- K1IN	insert is active
; 	    | 6 	    	- K1CL	caps-lock is active
; 	    |  5	    	- K1NL	num-lock is active
; 	    |   4    	- K1SL	scroll-lock is active
; 	    |    3   	- K1AL	ALT key depressed
; 	    |     2  	- K1CT	CTRL key depressed
; 	    |      1 	- K1LS	left shift key depressed
; 	    |       0	- K1RS	right shift key depressed
;----------------------------------------------------------------------------;
KBFLAGS1 RECORD	K1IN:1,K1CL:1,K1NL:1,K1SL:1,K1AL:1,K1CT:1,K1LS:1,K1RS:1
;----------------------------------------------------------------------------;
; 40:18	Keyboard Flags Byte 2 (High)
; 84218421
; 7 	    |			- K2IN	insert key is depressed
;  6 	    |			- K2CL	caps-lock key is depressed
;   5	    |			- K2NL	num-lock key is depressed
;    4    |			- K2SL	scroll lock key is depressed
;     3   |			- K2PA	pause (Ctrl-NumLock) is active
;      2  |			- K2SY	system key depressed and held
;       1 |			- K2LA	left ALT key depressed
;        0|			- K2LC	left CTRL key depressed
;----------------------------------------------------------------------------;
KBFLAGS2 RECORD	K2IN:1,K2CL:1,K2NL:1,K2SL:1,K2PA:1,K2SY:1,K2LA:1,K2LC:1

;----------------------------------------------------------------------------;
; FDC BDA Status Flags
;----------------------------------------------------------------------------;
; 40:3E	byte	Drive recalibration status
; 84218421
; 7 	    |			- FWIF	1=working interrupt flag
;  654    |			- FSTBD	unused
;     3   |			- FCAL3	1=recalibrate drive 3
;      2  |			- FCAL2	1=recalibrate drive 2
;       1 |			- FCAL1	1=recalibrate drive 1
;        0|			- FCAL0	1=recalibrate drive 0
FDC_SF RECORD	FWIF:1,FSTBD:3,FCAL3:1,FCAL2:1,FCAL1:1,FCAL0:1
;----------------------------------------------------------------------------;
; 40:3F	byte	Diskette motor status
; 84218421
; 7 	    |			- FWRT	1=write operation
;  654    |			- FMTBD	unused
;     3   |			- FMOT3	1=drive 3 motor on
;      2  |			- FMOT2	1=drive 2 motor on
;       1 |			- FMOT1	1=drive 1 motor on
;        0|			- FMOT0	1=drive 0 motor on
FDC_MF RECORD	FWRT:1,FMTBD:3,FMOT3:1,FMOT2:1,FMOT1:1,FMOT0:1

;----------------------------------------------------------------------------;
; FDC 765 Status Flags
;----------------------------------------------------------------------------;
; FDC Main Status Register at 3F4H (read only)
; 84218421
; 7 	    |			- FDRR	data reg ready for I/O to/from CPU
;  6      |			- FIOD	I/O direction; 1=FDC to CPU; 0=CPU to FDC
;   5     |			- FDND	FDC is in non-DMA mode
;    4    |			- FDRW	FDC read or write command in progress
;     3   |			- F3SK	floppy drive 3 in seek mode/busy
;      2  |			- F2SK	floppy drive 2 in seek mode/busy
;       1 |			- F1SK	floppy drive 1 in seek mode/busy
;        0|			- F0SK	floppy drive 0 in seek mode/busy
FDC_MSR RECORD	FDRR:1,FIOD:1,FDND:1,FDRW:1,F3SK:1,F2SK:1,F1SK:1,F0SK:1

;----------------------------------------------------------------------------;
; BDA 08FH Floppy drive mode
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- FM1X	unused
;  6      |			- FM1D	1=drive 1 determined
;   5     |			- FM1M	1=drive 1 supports multiple data rates
;    4    |			- FM18	1=drive 1 supports 80-track
;     3   |			- FM0X	unused
;      2  |			- FM0D	1=drive 0 determined
;       1 |			- FM0M	1=drive 0 supports multiple data rates
;        0|			- FM08	1=drive 0 supports 80-track
FDC_MODE RECORD	FM1X:1,FM1D:1,FM1M:1,FM18:1,FM0X:1,FM0D:1,FM0M:1,FM08:1

;----------------------------------------------------------------------------;
; BDA 90H-93H Floppy drive media state (drives 0-3)
;----------------------------------------------------------------------------;
; 84218421
; 76 	    |			- FSR		data xfr rate in Kb/s (0=500,1=300,2=250)
;   5     |			- FDDS	1=double stepping required
;    4    |			- FSE		1=media established
;     3   |			- FSX		unused
;      210|			- FSD		(see below)
;----------------------------------------------------------------------------;
; FSD values:
;	0 = 360K disk/360K drive not established
;	1 = 360K disk/1.2M drive not established
;	2 = 1.2M disk/1.2M drive not established
;	3 = 360K disk/360K drive established
;	4 = 360K disk/1.2M drive established
;	5 = 1.2M disk/1.2M drive established
;	6 = reserved
;	7 = none of the above
;----------------------------------------------------------------------------;
FDC_STATE RECORD	FSR:2,FDDS:1,FSE:1,FDX:1,FSD:3

;----------------------------------------------------------------------------;
; BIOS Printer Status Flags returned from INT 17
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- LPBZ	not busy (note: 0 means busy)
;  6      |			- LPACK	acknowledge (printer is attached)
;   5     |			- LPOP	20H out of paper
;    4    |			- LPSEL	10H selected (0 means off-line)
;     3   |			- LPIO	08H I/O error
;      21 |			- LPX		06H unused
;        0|			- LPTO	01H time-out error
PRN_STAT RECORD	LPBZ:1,LPACK:1,LPOP:1,LPSEL:1,LPIO:1,LPX:2,LPTO:1

;----------------------------------------------------------------------------;
; 6845 Video - Port 3DA Status Register
;----------------------------------------------------------------------------;
; 84218421
; 7654    |			- VSX		unused
;     3   |			- VSVS	vertical retrace, RAM access OK (next 1.25ms)
;      2  |			- VSPE	0 = light pen on, 1 = light pen off
;       1 |			- VSPT	light pen trigger set
;        0|			- VSHS	horiz or vert retrace, RAM access OK
VID_STAT RECORD	VSX:4,VSVS:1,VSPE:1,VSPT:1,VSHS:1

;----------------------------------------------------------------------------;
; 8255 PPI Channel B Flags
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PBKB	0=enable keyboard read, 1=clear
;  6      |			- PBKC	0=hold keyboard clock low, 1=enable clock
;   5     |			- PBIO	0=enable i/o check, 1=disable
;    4    |			- PBPC	0=enable memory parity check, 1=disable
;     3   |			- PBSW	0=read SW1-4, 1=read SW-5-8
;      2  |			- PBTB	0=turbo, 1=normal
;       1 |			- PBSP	0=turn off speaker, 1=turn on
;        0|			- PBST	0=turn off timer 2, 1=turn on 
PPI_B_F RECORD	PBKB:1,PBKC:1,PBIO:1,PBPC:1,PBSW:1,PBTB:1,PBSP:1,PBST:1

;----------------------------------------------------------------------------;
; Set up boot mode (PPI_B_BOOT) for PPI Channel B
;----------------------------------------------------------------------------;

			IF BOOT_SPEED EQ BOOT_TURBO
;----------------------------------------------------------------------------;
; Default Power-On: KB hold low+disable, NMI on, spkr data off, turbo ON/OFF
;
PPI_B_BOOT	= MASK PBKB OR MASK PBIO OR MASK PBSW OR MASK PBST

			ELSE
;----------------------------------------------------------------------------;
; Default Power-On: KB hold low+disable, NMI on, spkr data off, turbo OFF/ON
;
PPI_B_BOOT	= MASK PBKB OR MASK PBIO OR MASK PBSW OR MASK PBST OR MASK PBTB

			ENDIF

			IF TURBO_TYPE EQ TURBO_REV
;----------------------------------------------------------------------------;
; Reverse Turbo states
;
PPI_B_BOOT	= PPI_B_BOOT XOR MASK PBTB
			ENDIF

;----------------------------------------------------------------------------;
; 8255 PPI Channel C Flags (5160)
; * When PPI B PBSW = 0
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PCPE	0=no parity error, 1=memory parity error
;  6      |			- PCIE	0=no i/o channel error, 1=i/o channel error
;   5     |			- PCT2	timer 2 output
;    4    |			- PCCI	unused (cassette data input)
;     32  |			- PCMB	SW 3,4: MB RAM (00=64K, 01=128K, 10=192K, 11=256K)
;       1 |			- PCFP	SW 2: 0=no FPU, 1=FPU installed
;        0|			- PCFD	SW 1: Floppy drive (IPL) installed
PPI_C_X_L RECORD	PCPE:1,PCIE:1,PCT2:1,PCCI:1,PCMB:2,PCFP:1,PCFD:1

;----------------------------------------------------------------------------;
; 8255 PPI Channel C Flags (5160)
; * When PPI B PBSW = 1
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PC2PE	0=no parity error, 1 r/w memory parity check error
;  6      |			- PC2IE	0=no i/o channel error, 1 i/o channel check error
;   5     |			- PC2T2	timer 2 output
;    4    |			- PC2CI	cassette data input
;     32  |			- PCDRV	SW 7,8: # of drives (00=1, 01=2, 10=3, 11=4)
;       10|			- PCVID	SW 5,6: video Mode (00=ROM, 01=CG40, 10=CG80, 11=MDA)
PPI_C_X_H RECORD	PC2PE:1,PC2IE:1,PC2T2:1,PC2CI:1,PCDRV:2,PCVID:2


;============================================================================;
;
;	 			* * *   M A C R O S   * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; CALL NO STACK - a CALL without a writable stack
;----------------------------------------------------------------------------;
; Input:
;	CALL_JMP = address for CALL
;
; - SS must be CS
;----------------------------------------------------------------------------;
CALL_NS 	MACRO CALL_JMP
		LOCAL	CALL_JMP_PTR, CALL_JMP_RET
	MOV	SP, OFFSET CALL_JMP_PTR
	JMP	CALL_JMP
CALL_JMP_PTR:
	DW	OFFSET CALL_JMP_RET
CALL_JMP_RET:
		ENDM

;----------------------------------------------------------------------------;
; Introduce a short delay of ~15 clock cycles for I/O
;----------------------------------------------------------------------------;
; - Code size: 2 bytes
; - 15 clock cycles
; - Affects no registers or flags
; - CPU Instruction cache is purged
; - No stack required
;----------------------------------------------------------------------------;
IO_DELAY_SHORT	MACRO
		LOCAL _DONE
	JMP	SHORT _DONE
_DONE:
		ENDM

;----------------------------------------------------------------------------;
; Variable delay ~ CX * 15 clock cycles
;----------------------------------------------------------------------------;
; Input: CX delay in 15 clock cycle increments
; Output: CX = 0
;----------------------------------------------------------------------------;
IO_DELAY	MACRO
		LOCAL _DONE
_DONE:
	LOOP	_DONE					; long delay for I/O
		ENDM

;----------------------------------------------------------------------------;
; Long delay ~1.18m clock cycles (roughly 1/4 second on 4.77MHz)
;----------------------------------------------------------------------------;
; Output: CX = 0
;----------------------------------------------------------------------------;
IO_DELAY_LONG	MACRO
	XOR	CX, CX 				; delay 65535 LOOPs
	IO_DELAY
		ENDM

;----------------------------------------------------------------------------;
; Get an equipment flag
;----------------------------------------------------------------------------;
; Input:
;	FLAG = field name from EQUIP_FLAGS RECORD
;	SET_BDA = if defined, saves CX and sets DS = BDA
;		otherwise assumes DS = BDA and clobbers CX
; Output: AL = flag value
;----------------------------------------------------------------------------;
GET_EFLAG	MACRO	FLAG, SET_BDA
			IFNB <SET_BDA>
	PUSH	CX
	PUSH	DS
	MOV	CX, SEG _BDA
	MOV	DS, CX
			ENDIF
	MOV	AX, EQUIP_FLAGS
	AND	AX, MASK FLAG
			IF CPU_TYPE	EQ CPU_V20
	SHR	AX, FLAG
			ELSE
	MOV	CL, FLAG
	SHR	AX, CL
			ENDIF
			IFNB <SET_BDA>
	POP	DS
	POP	CX
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Test a single BDA equipment flag
;----------------------------------------------------------------------------;
; Input: FLAG = field name from EQUIP_FLAGS RECORD
; Output: ZF if 0, NZ if 1
;
; Requires: DS = BDA
;----------------------------------------------------------------------------;
TEST_EFLAG	MACRO	FLAG
	TEST	EQUIP_FLAGS, MASK FLAG
		ENDM

;----------------------------------------------------------------------------;
; Test a single GLaBIOS flag
;----------------------------------------------------------------------------;
; Input:
;	FLAG = field name from GB_FLAGS RECORD
; Output: ZF if 0, NZ if 1
;
; Requires: DS = BDA
;----------------------------------------------------------------------------;
TEST_GFLAG	MACRO	FLAG
	TEST	GB_FLAGS, MASK FLAG
		ENDM

;----------------------------------------------------------------------------;
; Set an equipment flag
;----------------------------------------------------------------------------;
; Input: 
;	AL = flag value (clobbered)
;	FLAG = field name from EQUIP_FLAGS RECORD
;	NO_REGS = if defined, clobbers CL and *requires* DS = BDA 
; Output: none
;----------------------------------------------------------------------------;
SET_EFLAG	MACRO	FLAG, NO_REGS
			IFB <NO_REGS>
	PUSH	CX
	PUSH	DS
	MOV	CX, SEG _BDA			; DS = BDA
	MOV	DS, CX
			ENDIF
	AND	AL, MASK FLAG SHR FLAG		; isolate flag's bit width
			IF CPU_TYPE	EQ CPU_V20
	SHL	AX, FLAG				; shift value into position
			ELSE
	MOV	CL, FLAG				; CL = bit(s) position of record
	SHL	AX, CL				; shift value into position
			ENDIF
	AND	EQUIP_FLAGS, NOT MASK FLAG	; clear existing flags
	OR	EQUIP_FLAGS, AX 			; set new flags
			IFB <NO_REGS>
	POP	DS
	POP	CX
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Shortcut to write a null-terminated string to console
;----------------------------------------------------------------------------;
; Input:
;	SZ = string to print
;	SAVE_REGS = define (anything) to preserve SI (cost of 2 bytes)
;----------------------------------------------------------------------------;
PRINT_SZ	MACRO	SZ, SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	SI					; save SI
		ENDIF
		IFDIFI <SZ>,<SI>			; if SZ is not SI
	MOV	SI, OFFSET SZ
		ENDIF
	CALL	OUT_SZ
		IFNB	<SAVE_REGS>
	POP	SI
		ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Same as above but print CRLF at the end
;----------------------------------------------------------------------------;
; Input:
;	SZ = string to print
;	SAVE_REGS = define (anything) to preserve SI (cost of 2 bytes)
;
; If called as PRINTLN_SZ SI, will use SI (effectively an alias to 
;	'CALL OUTLN_SZ')
;----------------------------------------------------------------------------;
PRINTLN_SZ	MACRO	SZ, SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	SI					; save SI
		ENDIF
		IFDIFI <SZ>,<SI>			; if SZ is not SI
	MOV	SI, OFFSET SZ
		ENDIF
	CALL	OUTLN_SZ
		IFNB	<SAVE_REGS>
	POP	SI
		ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Set text attribute for a block of chars starting at current cursor
;----------------------------------------------------------------------------;
; This is a more efficient way to set text colors so any normal way to write
; to console may be used.
;
; Example usage:
;   SET_SZ_ATTR 0EH, 10			; set attribute to 0EH for next 10 chars
;
; Code size:
; 	16 bytes if registers NOT saved
;	22 bytes if registers saved
; 	-3 bytes if ATTR is BL
;----------------------------------------------------------------------------;
SET_SZ_ATTR	MACRO	ATTR, LN, SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	AX
	PUSH	BX
	PUSH	CX
		ENDIF ; IFNB
	MOV	AX, 900H OR ' '		; AH = write char w/attr, AL = space
		IFDIFI <ATTR>,<BL>	; if ATTR is not BL
	MOV	BX, LOW ATTR		; BH = video page 0, BL = attribute
		ENDIF	; IFDIFI
	MOV	CX, LN			; CX = repeat times
	INT	10H
		IFNB	<SAVE_REGS>
	POP	CX
	POP	BX
	POP	AX
		ENDIF	; IFNB
		ENDM

;----------------------------------------------------------------------------;
; POST column UI
;----------------------------------------------------------------------------;
POST_COL_1	MACRO LBL_STR, INNER_ATTR, SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	BX					; save BX
		ENDIF
	MOV	BX, LOW INNER_ATTR
	MOV	SI, OFFSET LBL_STR
	CALL	POST_START_COL_1
		IFNB	<SAVE_REGS>
	POP	BX
		ENDIF

		ENDM

POST_COL_2	MACRO LBL_STR, INNER_ATTR, SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	BX					; save BX
		ENDIF
	MOV	BX, LOW INNER_ATTR
	MOV	SI, OFFSET LBL_STR
	CALL	POST_START_COL_2
		IFNB	<SAVE_REGS>
	POP	BX
		ENDIF
		ENDM

POST_COL_END	MACRO	SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	BX					; save BX
		ENDIF
	CALL	POST_END_COL
		IFNB	<SAVE_REGS>
	POP	BX
		ENDIF
		ENDM

POST_COL_END_NL	MACRO SAVE_REGS
		IFNB	<SAVE_REGS>
	PUSH	BX					; save BX
		ENDIF
	CALL	POST_END_COL_NL
		IFNB	<SAVE_REGS>
	POP	BX
		ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Beepin' MACROs
;----------------------------------------------------------------------------;
; Beep on Man
;----------------------------------------------------------------------------;
BEEP_ON MACRO 	TONE, NO_SAVE_REGS
		IFNB	<TONE>
	MOV	AX, TONE 			; custom tone
		ELSE
	MOV	AX, BEEP_DEFAULT
		ENDIF
		IFB	<NO_SAVE_REGS>
	PUSH	BX
		ENDIF
	CALL	BEEP_ON_P
		IFB	<NO_SAVE_REGS>
	POP	BX
		ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Beep off Man
;----------------------------------------------------------------------------;
BEEP_OFF MACRO
	CALL	BEEP_OFF_P
		ENDM

;----------------------------------------------------------------------------;
; BYTES_HERE - Track and enforce code/byte space around fixed ORGs
;----------------------------------------------------------------------------;
; Use to mark a block of free code space. Outputs assembly warning if code 
; overruns NEXT_LBL, and defines LBL so space can be viewed. Values displayed
; in generated listing.
;
; WTF: why can't MASM %OUT display the value of NEXT_LBL-$?
; WTF2: how to fix for MASM 6.1?
;
	.LALL
BYTES_HERE	MACRO	NEXT_LBL
		LOCAL LBL

BYTES_HERE_&NEXT_LBL = NEXT_LBL-$

		IFDEF BYTES_HERE_&NEXT_LBL
		IF2
		IF BYTES_HERE_&NEXT_LBL LT 0
		.ERR2
	%OUT WARNING: Out of space at: NEXT_LBL (&BYTES_HERE_&NEXT_LBL)
		ENDIF
		ENDIF
		ENDIF
		ENDM

;----------------------------------------------------------------------------;
; V20 MACROs
;
; Polyfill for V20 instruction mnemonics not supported by MASM.
; Not comprehensive of course.
;
TEST1_BP	MACRO IMM4
	DB	0FH, 19H, 0C5H, IMM4	; TEST1 BP, IMM4
		ENDM

NOT1_BP	MACRO IMM4
	DB	0FH, 1FH, 0C5H, IMM4	; NOT1  BP, IMM4
		ENDM

CLR1_BP	MACRO IMM4
	DB	0FH, 1BH, 0C5H, IMM4	; CLR1  BP, IMM4
		ENDM

SET1_BP	MACRO IMM4
	DB	0FH, 1DH, 0C5H, IMM4	; SET1  BP, IMM4
		ENDM

;----------------------------------------------------------------------------;
; Operations on POST test FLAGs
;----------------------------------------------------------------------------;
POST_FLAG_TEST MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20
	TEST1_BP  FLAG				; V20 only: TEST1 BP, FLAG
			ELSE
	TEST	BP, MASK FLAG			; Is flag set?
			ENDIF
		ENDM

POST_FLAG_SET MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20
	SET1_BP   FLAG				; V20 only: SET1 BP, FLAG
			ELSE
	OR	BP, MASK FLAG			; Set flag
			ENDIF
		ENDM

POST_FLAG_FLIP MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20
	NOT1_BP   FLAG				; V20 only: NOT1 BP, FLAG
			ELSE
	XOR	BP, MASK FLAG			; Invert flag
			ENDIF
		ENDM

POST_FLAG_CLR MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20
	CLR1_BP   FLAG				; V20 only: CLR1 BP, FLAG
			ELSE
	AND	BP, NOT MASK FLAG			; Clear flag
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Jump if Warm Boot
;----------------------------------------------------------------------------;
JWB		MACRO	LBL
	TEST	BP, BP				; is warm boot?
	JS	LBL					; jump if so
		ENDM

;----------------------------------------------------------------------------;
; Jump if not Warm Boot
;----------------------------------------------------------------------------;
JNWB		MACRO	LBL
	TEST	BP, BP				; is warm boot?
	JNS	LBL					; jump if not
		ENDM

;----------------------------------------------------------------------------;
; Wait for a video retrace to enable RAM access for CGA 80 column
;----------------------------------------------------------------------------;
; Input:
;	DX = 03DAH (CGA Status Port)
;
; Output:
;	Display is in retrace
;	CLI: Interrupts OFF - must be re-enabled after read/write operation
;
; https://forum.vcfed.org/index.php?threads/cant-get-rid-of-cga-snow.39319/post-478150
;
; Due to timing requirements this must be unrolled - CALL/PROC too slow
;----------------------------------------------------------------------------;
CGA_WAIT_SYNC	MACRO
		LOCAL	WAIT_NO_HSYNC, WAIT_BLANK, IN_VSYNC
			IF CGA_SNOW_REMOVE EQ 1
	CLI						; [2] disable interrupts
			ENDIF
WAIT_NO_HSYNC:
			IF CGA_SNOW_REMOVE GT 1
	STI						; [2] enable interrupts
	NOP						; [3] handle pending interrupts
	CLI						; [2] disable interrupts
			ENDIF
	IN	AL, DX				; [12] read CGA status register
			IF CGA_SNOW_REMOVE GT 1
	TEST	AL, MASK VSVS			; [5] in vertical?
	JNZ	IN_VSYNC				; [4/16] if so, do CGA I/O
			ENDIF
	SHR	AL, 1					; [2] in horizontal?
	JC	WAIT_NO_HSYNC			; [4/16] if so, wait for next one
WAIT_BLANK:
	IN	AL, DX				; [12] read CGA status register
			IF CGA_SNOW_REMOVE GT 1
	TEST	AL, MASK VSVS OR MASK VSHS	; [5] in either sync?
	JZ	WAIT_BLANK				; [4/16]
			ELSE
	SHR	AL, 1					; [2] in horizontal sync?
	JNC	WAIT_BLANK				; [4/16]
			ENDIF
IN_VSYNC:
		ENDM

;============================================================================;
;
;	   		   * * *   S E G M E N T S   * * * 
;
;============================================================================;

;----------------------------------------------------------------------------;
; 0000:0000 - 8086 INT vector table
;----------------------------------------------------------------------------;
_IVT		SEGMENT AT 0H
		ORG 8H*4
_INT_08H 		DW	?			; INT 08H - Timer
_INT_08H_SEG	DW	?			; INT 08H - Timer Segment
_INT_09H 		DW	?			; INT 09H - Keyboard
_INT_09H_SEG	DW	?			; INT 09H - Keyboard Segment
		ORG 10H*4
_INT_10H		DW	?			; INT 10H - BIOS video services
_INT_10H_SEG	DW	?			; INT 10H - Segment
		ORG 18H*4
_INT_18H		DW	?			; INT 18H - ROM BASIC
_INT_18H_SEG	DW	?			; INT 18H - Segment
		ORG 1DH*4
_INT_1DH		DD	?			; INT 1DH - CRTC param table
_INT_1EH		DD	?			; INT 1EH - Floppy param table
_INT_1FH		DD	?			; INT 1FH - User Font bitmap table
_IVT 		ENDS

;----------------------------------------------------------------------------;
; 0000:0400 - BIOS data area (BDA) - Zero Page Segment Addressing
; (Only used during early POST)
;----------------------------------------------------------------------------;
_BDA_ABS	SEGMENT AT 0H
		ORG 440H
FD_MOTOR_CT_ABS	DB	?			; 40:40H FD motor shutoff counter
		ORG 46BH
INT_LAST_ABS	DB	?			; 40:6BH POST / Interrupt happened?
		ORG 472H
WARM_FLAG_ABS	DW	?			; 40:72H Warm Boot Flag
_BDA_ABS	ENDS

;----------------------------------------------------------------------------;
; 0030:0000 - Bootstrap temporary stack
;----------------------------------------------------------------------------;
_BOOT_STACK	SEGMENT AT 30H
_TEMP_MEM	LABEL BYTE 				; use for scratch space during POST
			DW 	80H DUP(?)
STACK_TOP		DW 	?
_BOOT_STACK	ENDS

;----------------------------------------------------------------------------;
; 0040:0000 - BIOS data area (BDA)
;----------------------------------------------------------------------------;
; https://stanislavs.org/helppc/bios_data_area.html
;----------------------------------------------------------------------------;
_BDA		SEGMENT AT 40H
COM_ADDR		DW	4 DUP(?) 		; 00H  COM1-4 base addresses
LPT_ADDR		DW	3 DUP(?) 		; 08H  LPT1-3 base addresses
			DW	? 			; 0EH  Extended BIOS data area segment
EQUIP_FLAGS		EQFLAGS <> 			; 10H  Equipment Flags
GB_FLAGS		GFLAGS <> 			; 12H  Custom Equipment Flags
MEM_SZ_KB		DW	?			; 13H  Memory size in kilobytes
MEM_SZ_PC		DW	?			; 15H  Memory size SW2 on 5150
KB_FLAGS		LABEL WORD
KB_FLAGS1		DB	?			; 17H  Keyboard flags 1
KB_FLAGS2		DB	?			; 18H  Keyboard flags 2
KB_ALT 		DB	?			; 19H  Alt-keypad entry byte
KB_BUF_HD		DW	?			; 1AH  Keyboard buffer head ptr
KB_BUF_TL		DW	?			; 1CH  Keyboard buffer tail ptr
KB_BUF		DW	16 DUP(?) 		; 1EH  Keyboard buffer
KB_BUF_END		LABEL WORD
FD_CAL_ST		FDC_SF <>			; 3EH  Floppy drive recalibration status
							;	0 = drive not calibrated
							;	high bit = working interrupt flag
FD_MOTOR_ST		FDC_MF <>			; 3FH  FD motor status
							;	high bit = write operation
FD_MOTOR_CT		DB	?			; 40H  FD motor shutoff counter (decr. by INT 8)
FD_LAST_OP		DB	?			; 41H  BIOS Status of last FD operation
FDC_LAST_ST		DB	7 DUP(?)		; 42H  FDC command status last result (7 bytes)
VID_MODE		DB	?			; 49H  Current video mode
VID_COLS		DW	?			; 4AH  Number of screen columns
VID_BUF_SZ		DW	?			; 4CH  Size of video regen buffer in bytes
VID_SEG		DW	? 			; 4EH  Starting address in video regen buffer (offset) 
VID_CURS_POS	DW	8 DUP(?)		; 50H-5FH Cursor position of pages 1-8, high=row, low=col
VID_CURS_TYPE	DW	? 			; 60H  Starting (Top), Ending (bottom) scan line for cursor
VID_PAGE		DB	? 			; 62H  Active display page number
VID_PORT		DW	?			; 63H  Base port address for active 6845 CRT controller
VID_MODE_REG	DB	?			; 65H  6845 CRT mode control register value (port 3x8H)
VID_COLOR		DB	? 			; 66H  CGA current color palette setting (port 3D9H)
L_VID_BDA		EQU	$-VID_MODE		;      Length in bytes of video data in BDA
ROM_INIT_SS		DW	?			; 67H  Temp location for SS:SP during block move 
ROM_INIT_SP 	DW	? 			; 69H	  or Option ROM init
INT_LAST		DB	? 			; 6BH  Reserved for POST / Interrupt happened?
TIMER_CT_L		DW	?			; 6CH  Timer Counter Low Word (ticks)
TIMER_CT_H  	DW	? 			; 6EH  Timer Counter High Word (hours)
TIMER_CT_OF 	DB	? 			; 70H  Timer Overflow flag
BIOS_BREAK		DB	?			; 71H  BIOS break flag (high bit means ctrl-break)
WARM_FLAG		DW	?			; 72H  Warm Boot Flag (1234H to bypass RAM test)
HD_LAST_ST		DB 	? 			; 74H  Status of last hard disk operation (see INT 13,1)
HD_COUNT		DB 	? 			; 75H  Number of hard disks attached
HD_CTRL		DB 	? 			; 76H  XT fixed disk drive control byte
HD_PORT		DB 	? 			; 77H  Port offset to current fixed disk adapter
LPT_TIME		DB	4 DUP(?) 		; 78H  Time-out value for LPT1-4 (in # of 64K LOOPs)
COM_TIME		DB	4 DUP(?) 		; 7CH  Time-out value for COM1-4
KB_BUF_ST		DW	?			; 80H  Keyboard buffer start
			DW	?			; 82H  Keyboard buffer end
		ORG	08BH
			DB	?			; 8BH  Last diskette data rate selected
		ORG	08FH
FD_MODE		FDC_MODE <>			; 8FH  FDC Drive Mode (see FDC_MODE)
FD_MEDIA_ST		FDC_STATE 4 DUP(<>)	; 90H-93H  Drive 0-3 media state
FD0_TRACK		DB	?			; 94H  Drive 0 current track
FD1_TRACK		DB	?			; 95H  Drive 1 current track
KB_FLAGS3		DB	?			; 96H  Keyboard mode/type (Enhanced)
KB_FLAGS4		DB	?			; 97H  Keyboard LED flags (Enhanced)
		ORG	0ACH				; ACH-B3H "Reserved" (can be used?)
		ORG	0E8H				; E8H-EFH "Reserved" (can be used?)
CURSOR_DEFAULT	DW	?			; EAH  Power on cursor bottom:top scan line (for Turbo)
VID_MEM_SEG		DW	?			; ECH	 Videm mem segment (MDA = B000, CGA = B800)
;			DB	3 DUP(?)
_BDA		ENDS

;----------------------------------------------------------------------------;
; 0050:0000 - BIOS/DOS Data Area
;----------------------------------------------------------------------------;
_DOS_DAT	SEGMENT AT 50H
PTRSCN_ST		DB 	?			; 00H  Print screen status
			DB	3  DUP(?)		; 01H  Used by BASIC
			DB	?			; 04H  Floppy drive flag for single
							;		drive systems (0=A,1=B)
			DB	10 DUP(?)		; 05H  POST work area
			DB	19 DUP(?)		
DOS_FD_PARAM	DB	14 DUP(?)		; 22H  Floppy drive parameter table
	 		DB	4  DUP(?)		; 30H  Mode command
_DOS_DAT	ENDS

;----------------------------------------------------------------------------;
; 0070:0000 - "Kernel" of PC-DOS
;----------------------------------------------------------------------------;
_DOS_SEG	SEGMENT AT 70H
_DOS_SEG	ENDS

;----------------------------------------------------------------------------;
; 0000:7C00 - IPL / MBR / Boot Block Segment
;----------------------------------------------------------------------------;
_IPL_SEG	SEGMENT AT 0H
		ORG	07C00H
IPL_TOP		DB	510 DUP(?)		; MBR code then MBR magic number
IPL_ID		DW	?			; 0AA55H if valid MBR
_IPL_SEG	ENDS

;----------------------------------------------------------------------------;
; B000:0000 - MDA Video Memory
;----------------------------------------------------------------------------;
_MDA_MEM	SEGMENT AT 0B000H
			DB	1000H DUP(?)
MDA_MEM	LABEL BYTE				; 4KiB (1000H) total MDA memory
_MDA_MEM	ENDS

;----------------------------------------------------------------------------;
; B800:0000 - CGA Video Memory
;----------------------------------------------------------------------------;
_CGA_MEM	SEGMENT AT 0B800H
			DB	0800H DUP(?)
CGA_MEM_40	LABEL BYTE				; page 1 of CGA 40 column
			DB	0800H DUP(?)
CGA_MEM_80	LABEL BYTE				; page 1 of CGA 80 column
			DB	3000H DUP(?)
CGA_MEM_GFX	LABEL BYTE
CGA_MEM	LABEL BYTE				; 16KiB (4000H) total CGA memory
_CGA_MEM	ENDS

;----------------------------------------------------------------------------;
; C000:0000 - Video Option ROM segment
;----------------------------------------------------------------------------;
_VID_BIOS	SEGMENT AT 0C000H
VID_MN		DW	?			; magic number (0AA55H)
VID_BIOS_SZ		DB	?			; length in 512 byte blocks
VID_VEC		DW	?
_VID_BIOS	ENDS

;----------------------------------------------------------------------------;
; C800:0000 - Start of Storage/Other Option ROM segment
;----------------------------------------------------------------------------;
_OPT_ROM	SEGMENT AT 0C800H
_OPT_ROM	ENDS

;----------------------------------------------------------------------------;
; F000:E000 - System BIOS ROM segment map
;----------------------------------------------------------------------------;
_SEG_BIOS	SEGMENT AT 0F000H
		ORG	0E000H
_OFF_BIOS	LABEL WORD
		ORG	0E05BH
_COLD_BOOT		DW  ?
		ORG 0FFF0H
_POWER_ON 		DW  ?
_SEG_BIOS 	ENDS

;----------------------------------------------------------------------------;
; F600:0000 - ROM BASIC segment
;----------------------------------------------------------------------------;
_SEG_BASIC	SEGMENT AT 0F600H
_BASIC	LABEL WORD 				; offset for ROM BASIC start
_SEG_BASIC	ENDS


;============================================================================;
;
;				* * *   C O D E   * * * 
;
;============================================================================;

;----------------------------------------------------------------------------;
; Main BIOS ROM begins
;----------------------------------------------------------------------------;
; Note: Memory space from F000:0000 - F000:E05A is available, though the
; BIOS identifier string is typically at or near the top of this segment
;----------------------------------------------------------------------------;
		ASSUME	DS:_BIOS, SS:_BIOS, CS:_BIOS, ES:_BIOS
_BIOS    	SEGMENT

;----------------------------------------------------------------------------;
; F000:E000: Top of BIOS ROM 8K segment
;----------------------------------------------------------------------------;
		ORG	0E000H
BIOS_TOP	PROC NEAR

VER_BANNER	DB	LF
		DB	VER_NAME, ' [', HEART, '] '
				IF POST_SHOW_VER GT 2
		DB	"The hero we need but don't deserve"
		DB	CR, LF
				ENDIF

COPYRIGHT	DB	'(C)'
				IF POST_SHOW_VER GT 2
		DB	' '
				ENDIF
		DB	COPY_YEAR, ' '
		DB	'640KB Released under GPLv3'
				IF POST_SHOW_VER GT 1
		DB	LF
				ENDIF
		DB	0

BIOS_TOP 	ENDP

BYTES_HERE	POWER_ON			; 5 BYTES HERE


			ASSUME CS:_BIOS, DS:NOTHING, ES:NOTHING, SS:NOTHING
;----------------------------------------------------------------------------;
; F000:E05B: Beginning of boot execution
;----------------------------------------------------------------------------;
; Loosely follow these specs for BIOS POST operations:
;
; http://minuszerodegrees.net/5160/post/5160%20-%20POST%20-%20Detailed%20breakdown.htm
; http://minuszerodegrees.net/5150/post/5150%20-%20POST%20-%20Detailed%20breakdown.htm
; https://stanislavs.org/helppc/cold_boot.html
; http://philipstorr.id.au/pcbook/book1/post.htm
;----------------------------------------------------------------------------;
; POST Error Beep patterns:
;
; Short  Long
;	2	1	CPU register test failure
;	3	1	CPU instruction test failed
;	4	1	Build is V20 but not detected
;	2	2	System BIOS ROM checksum error
;	3	2	PIT counter 1 test failed
;	4	2	DMA register test failed
;	5	2	PIC test register failed
;	5	3	PIC test interrupt failed
;	1	3	Base RAM (0-16KB) read/write error
;	3	3	Error loading video adapter ROM
;	1	4	Base RAM (0-16KB) parity error
;----------------------------------------------------------------------------;
		ORG 0E05BH
POWER_ON 	PROC NEAR
	CLI 					; disable CPU interrupts
	CLD					; clear direction flag

;----------------------------------------------------------------------------;
; POST Hardware/System Tests
;----------------------------------------------------------------------------;

POST_CPU_TEST:
;----------------------------------------------------------------------------;
; [1] Test and clear all CPU Registers
;----------------------------------------------------------------------------;
; Check and set all registers to 0.
;
; On Failure: 1 long beep and 2 short beeps
;----------------------------------------------------------------------------;
	MOV	AX, RAM_TEST		; use the standard test pattern
CPU_REG_TEST:
	MOV	BX, AX			; the game of telephone
	MOV	DS, BX			;  pass a
	MOV	CX, DS			;  known value
	MOV	ES, CX			;  through all
	MOV	SI, ES			;  registers and
	MOV	SS, SI			;  ensure the
	MOV	DI, SS			;  same value
	MOV	BP, DI			;  makes it all
	MOV	SP, BP			;  the way
	MOV	DX, SP			;  to the end
	TEST	DX, NOT RAM_TEST		; expected result?
	MOV	BL, 21H 			; on Failure: 2 short and 1 long beep
	JNZ	HALT_ERROR
	XOR	AX, AX 			; otherwise repeat with AX = 0
	JNZ	HALT_ERROR			; if ZF was not set, it's not good
	TEST	DX, DX			; if zero it was second pass
	JNZ	CPU_REG_TEST		; Loop again to zero all registers
CPU_REG_PASS:

;----------------------------------------------------------------------------;
; Disable non-maskable interrupts (NMIs)
;----------------------------------------------------------------------------;
DISABLE_NMI:
	OUT	NMI_R0, AL			; write AL = 0 to NMI register port

;----------------------------------------------------------------------------;
; [1B] A brief test of flags and CPU instructions
;----------------------------------------------------------------------------;
; On Failure: 1 long beep and 3 short beeps
;----------------------------------------------------------------------------;
			IF POST_TEST_INST EQ 1
CPU_INST_TEST:
	MOV	AL, 1				; start off with some complicated math
	MOV	BL, 31H			; on error, 3 short and 1 long beep
	ADD	AL, AL			; can little Billy add 1 + 1?
	JS	HALT_ERROR			; ...better not be negative
	JZ	HALT_ERROR			; ...better not be zero
	JP	HALT_ERROR			; ...better have an odd number of 1 bits
	JC	HALT_ERROR			; ...better not be a borrower
	SUB	AL, 3				; 2 - 3 = ?
	JNS	HALT_ERROR			; ...better be negative
	JNP	HALT_ERROR			; ...better have even bits
	JNC	HALT_ERROR			; ...better have had to borrow
	CBW					; zero extend the result
	INC	AX				; roll it back over to 0
	JNZ	HALT_ERROR			; AX = 0
CPU_TEST_PASS:
			ENDIF

;----------------------------------------------------------------------------;
; [3] Set Zero Page Register for DMA channels 0 and 1
;----------------------------------------------------------------------------;
	OUT	DMA_P_C1, AL 		; AL = high nibble of segment for DMA (0)

;----------------------------------------------------------------------------;
; [4] Disable MDA/CGA adapters (for now)
;----------------------------------------------------------------------------;
INIT_VIDEO:
	MOV	DX, CGA_CTRL		; DX = 03D8H
	OUT	DX, AL 			; send Disable to CGA Mode Select Register
	INC	AX 				; clear MDA control, disable video signal
	MOV	DL, LOW MDA_CTRL		; DX = 03B8H
	OUT	DX, AL 			; send to MDA CRT Control Port

;----------------------------------------------------------------------------;
; Set up POST flags in BP
;----------------------------------------------------------------------------;
			ASSUME DS:_BDA_ABS
	CMP	WARM_FLAG_ABS, WARM_BOOT
	JNZ	POST_FLAG_DONE
	MOV	BP, MASK WARM		; clear and set POST warm boot flag
POST_FLAG_DONE:

;----------------------------------------------------------------------------;
; Setup SS = CS
;----------------------------------------------------------------------------;
; Set up temporary stack to point at ROM to enable CALL_NS MACRO
;----------------------------------------------------------------------------;
	MOV	DX, CS 			; SS to temp boot stack CS
	MOV	SS, DX			; SS to 0F000h BIOS segment

;----------------------------------------------------------------------------;
; [5] Setup 8255 PPI to normal operating state
;----------------------------------------------------------------------------;
; Normal operation: Mode 0, Ports A,C (U and L) as INPUT, Port B as OUTPUT
;   1 		- Active
;    00 		- A Mode 0
;      1 		-  Port A - Input
;       1 		-  Port C (Upper) - Input
;        0 		- B Mode 0
;         0 	-  Port B - Output
;          1 	-  Port C (Lower) - Input
;----------------------------------------------------------------------------;
RESET_PPI:
	MOV	AL, 10011001B 		; set 8255 A,C to INPUT, B to OUTPUT
	OUT	PPI_CW, AL 			; send to PPI control port

;----------------------------------------------------------------------------;
; Set up PPI port B
;
	MOV	AL, PPI_B_BOOT		; KB hold low+disable, NMI on, spkr off
	OUT	PPI_B, AL			; send to 8255 Port B

			IF TURBO_TYPE EQ TURBO_90H
;----------------------------------------------------------------------------;
; Set up Turbo mode for ST-xx
;
	IN	AL, TURBO_CTRL_90H	; read current register
			IF BOOT_SPEED EQ BOOT_TURBO
	MOV	AL, 0010B
			ELSE
	MOV	AL, 0011B
			ENDIF
	OUT	TURBO_CTRL_90H, AL	; write new register
			ENDIF

			IF POST_TEST_CHK_ROM EQ 1
;----------------------------------------------------------------------------;
; [8] Checksum (8 bit) the main ROM to ensure it is not corrupt
;----------------------------------------------------------------------------;
; Input: AH = 0, DX = 0F000h
; On Failure: 2 long beep and 2 short beeps
;----------------------------------------------------------------------------;
	JWB	CHECKSUM_OK			; skip on warm boot
CHECKSUM_ROM:
			ASSUME DS:_BIOS
	MOV	DS, DX			; DS to 0F000h BIOS segment
	MOV	SI, OFFSET BIOS_TOP 	; offset to top of BIOS ROM
	MOV	CH, 10H			; checksum 8KB (in 2 byte words)
	CWD					; DL = accumulator for sum, DH = 0
CHECKSUM:
	LODSW 				; next two bytes into AL and AH
	ADD	DL, AL
	ADD	DL, AH			; ZF if sum is 0
	LOOP	CHECKSUM 			; loop through entire ROM
	MOV	BL, 22H 			; on failure, 2 short and 2 long beeps
	JNZ	HALT_ERROR			; if sum not 0, fail
CHECKSUM_OK:
			ENDIF

;----------------------------------------------------------------------------;
; [9] Disable the 8237 DMA controller chip.
;----------------------------------------------------------------------------;
INIT_DMA1:
	MOV	AL, 00000100B		; Set Controller Disable bit
	OUT	DMA_CMD, AL 		; write to DMA Command Register

			IF POST_TEST_PIT_1 EQ 1
;----------------------------------------------------------------------------;
; [10] Test Channel #1 on 8253 timer chip.
;----------------------------------------------------------------------------;
; Channel #1 on 8253 timer chip. Channel #1 is used in RAM refresh process.  
; If the test fails, beep failure code
;
; Test that all data lines are working by reading counter and checking 
; that all bits from counter go both high and low.
;----------------------------------------------------------------------------;
; Use 16-bit mode to test low three address lines using high byte of counter.
; This avoids a situation where the read counter code is a binary multiple
; of the counter causing a bit to not be observed as changing.
;
; Control Word Counter 1 (port 43H) - System Timer:
;  01 		- SC: Select Counter 1
;    11		- RW: Read/Write 2xR/2xW
;      010		- M:  Mode 2, Rate Gen
;         0		- BCD: 0
;
	MOV	AL, 01110100B		; Control Word: Counter 1
						;   Format: R/W low/high byte
						;   Mode: 2 Rate Gen, BCD: 0
	OUT	PIT_CTRL, AL		; set Counter mode
	MOV	DX, LOW PIT_CH1		; DX = PIT channel 1
	OUT	DX, AL			; set low byte (any value)
	MOV	SI, 0FFH SHL 3		; look at bits 10-3 for 1 check
	MOV	DI, NOT 0FFH SHL 3	; look at bits 10-3 for 0 check
	OUT	DX, AL			; set high byte (any value)
INIT_PIT1_TEST:
	CMP	SI, 0FFFFH			; have all bits flipped to 1?
	JNZ	INIT_PIT1_TEST_READ
	TEST	DI, DI			; have all bits flipped to 0?
	JZ	INIT_PIT1_TEST_DONE
INIT_PIT1_TEST_READ:
	MOV	AL, 01000000b		; latch Counter 1 command
	OUT	PIT_CTRL, AL		; write command to CTC
	IN	AL, DX			; read timer LSB
	XCHG	AH, AL			; save LSB
	IN	AL, DX			; read timer MSB
	AND	DI, AX			; clear all lines received as 0
	OR	SI, AX			; set all lines received as 1
	LOOP	INIT_PIT1_TEST		; loop until timeout
	MOV	BL, 32H 			; beep pattern (3 short, 2 long)
HALT_ERROR:
	JMP	SHORT HALT_BEEP_1		; NEAR jump for POST errors
			ELSE
	JMP	SHORT INIT_PIT1_TEST_DONE ; jump over the NEAR jump
HALT_ERROR:
	JMP	SHORT HALT_BEEP_1		; must still be here if PIT test is off
	IO_DELAY_SHORT			; I/O delay
			ENDIF

INIT_PIT1_TEST_DONE:

;----------------------------------------------------------------------------;
; [9B] 8253 PIT Programmable Interval Timer Initialization Channel 1
;----------------------------------------------------------------------------;
; Counter 1 - DRAM Refresh
;----------------------------------------------------------------------------;
INIT_PIT1:
	MOV	AL, 01010100B		; Control Word: Counter 1
						;   Format: R/W low byte
						;   Mode: 2 Rate Gen, BCD: 0
	OUT	PIT_CTRL, AL		; set Counter mode

;----------------------------------------------------------------------------;
; [12] Reset, Clear and test DMA Offset and Block Size Registers
;----------------------------------------------------------------------------;
; - Master Reset of DMA controller
; - Test 8237 DMA Address/Count Register channels 0-3
;----------------------------------------------------------------------------;
	OUT	DMA_RESET, AL 		; Master Reset (send any value of AL)

			IF POST_TEST_DMA EQ 1
	MOV	BH, 8				; test 8 ports
	XOR	DX, DX			; starting at port 00H
	CALL_NS WB_TEST			; ZF and CX = 0 if pass, NZ if failed
	MOV	BL, 42H 			; beep pattern (4 short, 2 long)
	JNZ	HALT_ERROR
DMA_PASS:
	OUT	DMA_RESET, AL 		; master reset of DMA again
			ENDIF			; POST_TEST_DMA

			IF DRAM_REFRESH
;----------------------------------------------------------------------------;
; [13] Set Counter DMA Channel 0 for memory refresh
;----------------------------------------------------------------------------;
; https://www.reenigne.org/blog/how-to-get-away-with-disabling-dram-refresh/
;----------------------------------------------------------------------------;
	MOV	AL, 0FFH			; Memory refresh counter (16-bit) is 0FFFFH
	OUT	DMA_0_C, AL			; write low order bits
	NOP					; very short I/O delay
	OUT	DMA_0_C, AL			; write high order bits

;----------------------------------------------------------------------------;
; [13] Set Mode DMA Channel 0
;----------------------------------------------------------------------------;
; 01 			; Mode 1 (Single)
;   0 		; INC: address decrement
;    1 		; Auto-initialization
;     10 		; type: Read from memory
;       00 		; Channel 0
;----------------------------------------------------------------------------;
	MOV	AL, 01011000B		; see above
	OUT	DMA_MODE, AL		; write to DMA Mode Register

;----------------------------------------------------------------------------;
; [13B] 8253 Timer set channel #1 for DMA/DRAM refresh
;----------------------------------------------------------------------------;
	MOV	AL, 18 			; divisor: 1.19318 MHz / 18 = 66,287.7 Hz
	OUT	PIT_CH1, AL			; refresh DRAM every 2ms
			ENDIF

;----------------------------------------------------------------------------;
; [13C] Enable DMA and clear mask register on Channels 0-3
;----------------------------------------------------------------------------;
	MOV	AL, 0 			; Set Controller Enable bit
	OUT	DMA_CMD, AL 		; write to DMA Command Register
	MOV	CL, 3				; Set mode on Channels 1-3 for [13D]
	OUT	DMA_MASK, AL		; clear mask (enable) on all channels

;----------------------------------------------------------------------------;
; [13D] Set default Mode for DMA Channels 1-3
;----------------------------------------------------------------------------;
; 01 			; Mode 1 (Single)
;   0 		; INC: address decrement
;    0 		; No Auto-initialization
;     00 		; type: Verify
;       xx 		; Channels 1-3
;
; Input: CL = 3 from [13C], CH = 0 from CALL_NS in [12]
;----------------------------------------------------------------------------;
	MOV	AL, 01000001B		; AL = 01000001
DMA_SETUP_CH:
	OUT	DMA_MODE, AL		; write to DMA Mode Register
	INC	AX				; next channel
	LOOP	DMA_SETUP_CH		; (delay 13-17 clocks between OUTs)

;----------------------------------------------------------------------------;
; [14] Detect and enable expansion chassis / extension card
;----------------------------------------------------------------------------;
; http://minuszerodegrees.net/5161/doco/5161_documentation.htm
;
; http://minuszerodegrees.net/5161/misc/5161_not_supported.htm
; "note: research revealed that the substituted code is not required; the circuit 
; diagram of the extender card shows that the card is automatically enabled 
; at application of power."
;
; Based on the above, it would appear this is not necessary at all.
;----------------------------------------------------------------------------;
;INIT_EXP_CHASSIS:
;	MOV	DX, 213H			; PC Expansion Chassis
;	IN	AL, DX
;	INC	AL 				; Is 213H == 0FFH?
;	JZ	NO_EXP_CHASSIS 		; if so, no expansion chassis
;	MOV	AL, 1 			; otherwise, send 1 to enable
;	OUT	DX, AL
;NO_EXP_CHASSIS:

;----------------------------------------------------------------------------;
; [15] Test and zero first 16KB of RAM
;----------------------------------------------------------------------------;
; This is necessary to utilize the BIOS Data Area and a usable stack
;
; Parity bits are in an indeterminate state on power up so parity check must
; be disabled until memory is written once.
;
; On failure: 
; - Read/Write Error: 1 short, 3 long beeps
; - Parity Error: 1 short, 4 long beeps
;
; Input: CX = 0 from [13D]
;----------------------------------------------------------------------------;
			ASSUME DS:_BDA_ABS, ES:_IVT
BASE_RAM_TEST:
	IN	AL, PPI_B 				; AL = PB0 flags
	OR	AL, MASK PBIO OR MASK PBPC	; disable RAM parity and I/O ch. flags
	OUT	PPI_B, AL
	XCHG	AX, CX				; AX = 0 = MEM_CHECK pattern and
	MOV	DS, AX				; DS and ES = IVT segment 0000
	MOV	ES, AX
	MOV	SI, OFFSET WARM_FLAG_ABS	; preserve warm boot flag
	MOV	DX, WORD PTR[SI]			; save warm boot flag
	CALL_NS MEM_CHECK				; clear memory and parity bits
	JNZ	BASE_RAM_ERROR
	IN	AL, PPI_B				; read PPI channel B
	OR	AL, MASK PBPC 			; clear MB RAM parity flag only
	OUT	PPI_B, AL
	AND	AL, NOT MASK PBPC 		; enable MB RAM parity for test
	OUT	PPI_B, AL
	CALL_NS MEM_ADDR_TEST			; test address lines
	JZ	BASE_RAM_ZERO			; continue if no errors
BASE_RAM_ERROR:
	MOV	BL, 13H 				; on failure, 1 short and 3 long beeps
HALT_BEEP_1:
	JMP	HALT_BEEP				; NEAR jump to HALT BEEP PROC
BASE_RAM_ZERO:
	MOV	AX, RAM_TEST			; test pattern
	CALL_NS MEM_CHECK				; write and verify test pattern
	JNZ	BASE_RAM_ERROR			; ZF and AX = 0 if okay
	CALL_NS MEM_CHECK				; write and verify zeros
	JNZ	BASE_RAM_ERROR
	MOV	WORD PTR[SI], DX			; restore warm boot flag
	INC	AX					; AL = 1
	MOV	FD_MOTOR_CT_ABS, AL 		; set motor to turn off on next tick
	IN	AL, PPI_C				; read PPI channel C
	AND	AL, MASK PCPE			; check MB RAM parity flag
	JZ	BASE_RAM_TEST_DONE		; either set?
	MOV	BL, 14H				; Halt with 1 short beep, 4 long beeps
	JMP	SHORT HALT_BEEP_1
BASE_RAM_TEST_DONE:
	IN	AL, PPI_B
	OR	AL, MASK PBIO OR MASK PBPC	; disable RAM parity and I/O ch. flags
	OUT	PPI_B, AL

;----------------------------------------------------------------------------;
;
; YAY! It's now okay to use the first 16KB of RAM: 0000:0000-0000:1FFF
;
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; [18] Setup BOOT R/W stack memory segment
;----------------------------------------------------------------------------;
			ASSUME SS:_BOOT_STACK
	MOV	AX, SEG STACK_TOP 		; SP to temp boot stack 0030:0100
	MOV	SS, AX
	MOV	SP, OFFSET STACK_TOP

;----------------------------------------------------------------------------;
; [19] 8259A PIC Interrupt controller Initialization
;----------------------------------------------------------------------------;
; PIC chip Initialization as follows:
;
; ICW1:
;  000 		- A7-A5: unused on 8086 mode
;     1 		- D4:   1 = ICW1 (and Port 0)
;      0 		- LTIM: 0 = Edge Triggered Mode (low to high TTL transition)
;       0 		- ADI:  0 = Call Address Interval of 8
;        1 		- SNGL: 1 = Single mode (no cascading PICs or ICW3)
;         1		- IC4:  1 = ICW4 Needed
;----------------------------------------------------------------------------;
; ICW2:
;  00001 		- T7-T3: Interrupt Vector Address:
;				INT = INT | 8 -> IRQ 0-7 to CPU INT 8-15
;       000 	- D2-D0: unused on 8086 mode
;----------------------------------------------------------------------------;
; ICW4:
;  000 		- D7-D5: unused
;     0		- SFNM: 0 = Not Special Fully Nested Mode
;      10		- BUF:  2 = Buffered Mode/Slave
;        0		- AEOI: 0 = normal EOI
;         1		- uPM:  1 = 8086 system
;----------------------------------------------------------------------------;
	MOV	DX, INT_P0			; DX = PIC Port 0
	MOV	AL, 00010011B		; ICW1 - Port 0
	OUT	DX, AL
	INC	DX				; DX = PIC Port 1
	MOV	AL, 00001000B		; ICW2 - Port 1
	OUT	DX, AL
	MOV	BH, 1				; short delay and test 1 port for [22]
	MOV	AL, 00001001B		; ICW4 - Port 1
	OUT	DX, AL

			IF POST_TEST_PIC_REG EQ 1
;----------------------------------------------------------------------------;
; [22] 8259A PIC Test
;----------------------------------------------------------------------------;
; - Read and write registers (IMR) and verify result
;----------------------------------------------------------------------------;
	CALL	WB_TEST			; walking bit test of PIC IMR register
	MOV	BL, 52H			; beep error 5 short, 2 long
	JZ	PIC_REG_PASS
PIC_INT_FAIL:
	JMP	SHORT HALT_BEEP_1
PIC_REG_PASS:
	DEC	DX				; DX = Port 1 (0021h)
			ELSE
	NOP
			ENDIF			; IF POST_TEST_PIC_REG EQ 1

	MOV	AL, 11111111B		; OCW1 - mask all interrupts (for now)
	OUT	DX, AL			; write IMR to PIC

			IF POST_TEST_PIC_INT EQ 1
;----------------------------------------------------------------------------;
; - Set up test interrupt handler for all interrupts
;
PIC_INT_TEST:
	MOV	CL, 20H			; 0 - 1FH BIOS vectors (LOW L_VECTOR_TABLE)
	XOR	DI, DI			; DI = beginning to IVT
PIC_VECT_TMP_LOOP:
	MOV	AX, OFFSET INT_IRQ	; offset for handler
	STOSW					; write to IVT
	MOV	AX, CS			; segment for hanlder (BIOS)
	STOSW					; write to IVT
	LOOP	PIC_VECT_TMP_LOOP

;----------------------------------------------------------------------------;
; - Mask all interrupts and ensure none are received
;
	MOV	DI, OFFSET INT_LAST_ABS
	MOV	[DI], DH			; clear last interrupt flag (DH = 0)
	STI					; enable interrupts
	IO_DELAY				; wait for it...
	CLI
	INC	BX				; beep error 5 short, 3 long (out of bytes!)
	OR	[DI], AL			; did any interrupts happen?

			IF POST_TEST_PIC_REG EQ 1
	JNZ	PIC_INT_FAIL
			ELSE
	JZ	PIC_INT_PASS
	JMP	SHORT HALT_BEEP_1
			ENDIF			; IF POST_TEST_PIC_REG EQ 1
			ENDIF			; IF POST_TEST_PIC_INT EQ 1

	MOV	AL, 11111110B		; OCW1 - unmask timer
	OUT	DX, AL			; write IMR to PIC

PIC_INT_PASS:

;----------------------------------------------------------------------------;
; [23] Setup Channel #0 on 8253 timer chip.
;----------------------------------------------------------------------------;
; Control Word Counter 0 (port 43H) - System Timer:
;  00 		- SC: Select Counter 0
;    11		- RW: Read/Write 2xR/2xW
;      011		- M:  Mode 3, Square Wave
;         0		- BCD: 0
;----------------------------------------------------------------------------;
	MOV	AL, 00110110B 		; Send CW to Counter 0 (see above)
	OUT	PIT_CTRL, AL
	PUSH	CS				; I/O delay and set up for DS = CS below

;----------------------------------------------------------------------------;
; This is what generates IRQ 0 (system timer).
; Timer set channel #0 output to a square wave of approx. 18.2 Hz based on
;	f = 1,193,180 / 10000H = ~ 18.2Hz
; Reload counter to WORD (0) to port 40H
;
	XOR	AL, AL			; reload counter is 2^16 (0) ~ 18.2Hz
	OUT	PIT_CH0, AL	  		; send low byte
	POP	DS				; I/O delay and set DS = CS
	OUT	PIT_CH0, AL 		; send high byte

;----------------------------------------------------------------------------;
; [25] Setup default BIOS interrupt vectors (0x0 - 0x1F)
;----------------------------------------------------------------------------;
; All segments are set to BIOS (CS) segment by default.
; Exceptions (such as ROM BASIC) are reset below.
;----------------------------------------------------------------------------;
			ASSUME DS:_BIOS, ES:_IVT
INIT_SW_INT_VECTORS:
	MOV	AX, CS 				; AX to BIOS segment
	MOV	CL, 20H				; 0 - 1FH BIOS vectors (LOW L_VECTOR_TABLE)
	XOR	DI, DI				; DI = beginning to IVT
	MOV	SI, OFFSET VECTOR_TABLE
BIOS_INT_VECTORS_LOOP:
	MOVSW 					; copy vector offset to IVT
	STOSW 					; write BIOS/CS segment
	LOOP	BIOS_INT_VECTORS_LOOP		; loop and set CX = 0

			IF BASIC_ROM EQ 1
;----------------------------------------------------------------------------;
; Check for valid BASIC ROMs and set INT 18H vector if detected
;----------------------------------------------------------------------------;
; - Scan 4 x 8K ROMs starting at seg 0F600h.
; - BASIC dectected if for alls ROMs, all of the folowing are true:
; 	- first two bytes not option ROM (0AAFFh)
;	- first two bytes not the same as the previous ROM (this checks to
;		 make sure are not all 0000 or FFFF)
;	- 8K ROM block has a valid checksum at offset 1FFE
;----------------------------------------------------------------------------;
			ASSUME DS:_SEG_BASIC
INIT_ROM_BASIC_SEG:
	MOV	BX, SEG _SEG_BASIC 		; BX = BASIC SEG in ROM
	MOV	DX, BX				; DX = save first BASIC SEG
	MOV	DI, MAGIC_WORD			; start with a negative check result
	MOV	CL, 4					; checksum 4 x 8K ROMs
CHECK_BASIC_ROM:
	MOV	DS, BX				; set DS to current segment
	MOV	AX, WORD PTR[_BASIC]		; AX = first two bytes
	CMP	AX, MAGIC_WORD			; is an option ROM?
	JE	INIT_ROM_BASIC_DONE		; if so, not ROM BASIC
	XCHG	AX, DI				; save last ROM's header to DI
	CMP	AX, DI				; is same as last ROM?
	JE	INIT_ROM_BASIC_DONE		; if so, valid ROM not present
	MOV	AL, 10H 				; ROM Size = 8K (10h * 512B)
	ADD	BH, 2					; BX = next BASIC 8K ROM
	CALL	ROM_CHECKSUM 			; checksum ROM at DS:0, size AL
	LOOPZ	CHECK_BASIC_ROM			; loop 4 ROMs or checksum fail
	JNZ	INIT_ROM_BASIC_DONE		; if NZ, checksum failed

;----------------------------------------------------------------------------;
; BASIC ROM detected - set as INT 18h in IVT
;
	MOV	DI, OFFSET _INT_18H		; DI = BASIC offset in IVT
	XOR	AX, AX				; vector offset is :0000
	STOSW 					; write to IVT
	XCHG	AX, DX 				; AX = BASIC SEG
	STOSW						; write to IVT
INIT_ROM_BASIC_DONE:
			ENDIF

;----------------------------------------------------------------------------;
; [18] Setup DS and ES to BDA segment
;----------------------------------------------------------------------------;
			ASSUME DS:_BDA, ES:_BDA
	MOV	AX, SEG _BDA 			; DS and ES to BDA
	MOV	DS, AX
	MOV	ES, AX

;----------------------------------------------------------------------------;
; Check CPU type
;----------------------------------------------------------------------------;
; If V20 is build target but V20 not detected - beep 1 long, 4 short
;----------------------------------------------------------------------------;
	CALL	CPU_IS_V20				; ZF = 1 if V20, ZF = 0 if 8088
	JNZ	CPU_TYPE_8088			; jump if not V20
	OR	GB_FLAGS, MASK V20		; set V20 flag
	JMP	SHORT CPU_TYPE_DONE		; continue booting
CPU_TYPE_8088:
			IF CPU_TYPE	EQ CPU_V20
	MOV	BL, 41H				; Build is V20 but not detected
	JMP	HALT_BEEP
			ENDIF
CPU_TYPE_DONE:

;----------------------------------------------------------------------------;
; [14] Read DIP switch settings and init proper EQUIP_FLAGS
;----------------------------------------------------------------------------;
;
; https://sites.google.com/site/pcdosretro/biosdata
; https://stanislavs.org/helppc/int_11.html
;
; 5150 Sense Switches:
;  Port A - when Port B bit 7 = 1
;     High| Low
; 	00  |			; Disk Drives (00=1, 01=2, 10=3, 11=4)
; 	  00| 		; Video (00=EGA/VGA, 01=CGA 40, 10=CGA 80, 11=MDA)
;	    |00		; MB RAM (00=16KB, 01=32K, 10=48K, 11=64K)
;	    |  0		; FPU installed ("Reserved")
; 	    |   0		; IPL Floppy Disk Drive (0=floppy drive installed)
;  Port C - I/O RAM (x 32KB)
;	High| Low
;	    |4321		; RAM size bits 1-4   when Port B bit 2 = 1
;	     4325		; RAM size bits 5,2-4 when Port B bit 2 = 0
;----------------------------------------------------------------------------;
; 5160 Sense Switches:
;  Port C
;	High| Low
; 	00  |			; Disk Drives (00=1, 01=2, 10=3, 11=4)
; 	  00| 		; Video (00=EGA/VGA, 01=CGA 40, 10=CGA 80, 11=MDA)
;	    |00		; MB RAM Banks (00=Bank 0, Bank 0/1, 10=0/1/2, 11=0/1/2/3)
;	    |  0		; FPU installed
; 	    |   0		; Test Loop (always 0)
;
; EQUIP_FLAGS: LPT:2,X1:1,GAM:1,COM:3,DMA:1,FLP:2,VIDM:2,MBRAM:2,FPU:1,IPL:1
;----------------------------------------------------------------------------;
GET_SW_SETTINGS:
	IN	AL, PPI_B 				; read Port B register
	PUSH	AX					; save original switches

		IF ARCH_TYPE EQ ARCH_5150
;----------------------------------------------------------------------------;
; Is a 5150 build
;
SETTINGS_5150:
	OR	AL, 10000100b			; Enable SW1 switches, SW2 1-4
	OUT	PPI_B, AL
	XCHG	AX, CX				; save modified settings

;----------------------------------------------------------------------------;
; Read 5150 memory size from SW1 3,4 (motherboard) and SW2 1-5 (expansion)
;
	IN	AL, PPI_C				; get expansion card memory size
	AND	AL, 1111b				; isolate memory size (in 32KB)
	MOV	CH, AL				; save low 4 bits
	XCHG	AX, CX				; AL = switches, AH = low 4 bits
	AND	AL, 11111011b			; Read SW2 5
	OUT	PPI_B, AL
	IN	AL, PPI_C				; read bit 5
	AND	AL, 0001b				; isolate memory size bit 5
	MOV	CL, 4
	SHL	AL, CL				; shift into correct position
	OR	AL, AH				; combine with bits 1-4
	CBW						; clear AH
	INC	CX					; convert to KB (CL = 5)
	SHL	AX, CL				; AX = blocks * 32
	XCHG	AX, DX				; DX = expansion RAM in KB

;----------------------------------------------------------------------------;
; Get motherboard RAM size
;
	IN	AL, PPI_A				; get drive, MB RAM, video
	PUSH	AX					; save SW1
	AND	AL, 1100b				; isolate MB RAM
	ADD	AL, 4					; start at 16KB since SW1 00 = 16KB
	SHL	AX, 1					; AX = MB RAM size in KB
	SHL	AX, 1					; (AX = AX * 4)
	ADD	AX, DX				; add expansion RAM to total
	MOV	MEM_SZ_PC, AX			; save to BDA
	POP	AX					; restore SW1

		ELSE
;----------------------------------------------------------------------------;
; Is a 5160 or standard clone build
;
SETTINGS_5160:
	AND	AL, 11110111B 			; set bit 3 = 0 for low switch select
	PUSH	AX		 			; save port settings
	OUT	PPI_B, AL
	IN	AL, PPI_C 				; get low switches
	AND	AL, MASK MBRAM OR MASK FPU OR MASK IPL ; isolate MB RAM and FPU bits
	MOV	CH, AL				; save to CH
	POP	AX 					; get port settings
	OR	AL, 00001000B 			; set bit 3 = 1 for high switch select
	OUT	PPI_B, AL
	IN	AL, PPI_C 				; get high switches
			IF CPU_TYPE	EQ CPU_V20
	SHL	AL, 4					; shift drives and video to high nibble
			ELSE
	MOV	CL, 4
	SHL	AL, CL				; shift drives and video to high nibble
			ENDIF
	OR	AL, CH				; combine RAM, FPU with drives and vid

		ENDIF

;----------------------------------------------------------------------------;
; If set on MB DIP SW1, test and verify FPU. If not detected, disable in BDA.
;
	TEST	AL, MASK FPU			; is FPU set?
	JZ	SETTINGS_SAVE			; if not, skip to save flags
	XCHG	AX, DI				; save AX (clobbered by HAS_FPU)
	CALL	HAS_FPU				; check FPU, ZF=0 if not detected
	XCHG	AX, DI
	JZ	SETTINGS_SAVE			; if detected, save flags
	AND	AL, NOT MASK FPU			; otherwise clear FPU flag
SETTINGS_SAVE:
	MOV	BYTE PTR EQUIP_FLAGS, AL	; set to low byte of EQUIP_FLAGS
	XCHG	AX, DX				; save EQUIP_FLAGS to DL for later
	POP	AX
	OUT	PPI_B, AL				; restore original settings

;----------------------------------------------------------------------------;
; [21] Video BIOS Option ROM scan
;----------------------------------------------------------------------------;
; Scan 0C000H - 0C800H for video option ROMs (EGA, VGA, etc)
;
; A video option ROM should set the BDA video type flag to a non-zero value
; If the flag is still 0 afterwards, no ROMs loaded succesfully.
;----------------------------------------------------------------------------;
	MOV	AX, SEG _VID_BIOS			; starting segment (C000H)
	MOV	DI, SEG _OPT_ROM			; ending segment (C800H)
	PUSH	DX					; save EQUIP_FLAGS for below
	CALL	BIOS_ROM_SCAN			; scan segments AX to DI for ROMs
	POP	DX					; restore EQUIP_FLAGS

;----------------------------------------------------------------------------;
; Check for a valid video mode in BDA:
;  - If BDA video mode is 0, video option ROM was not loaded. Beep and halt
;  - If MB video switch is 0 (option ROM), skip reset
;  - If not 0, determine correct 6845 video mode and do INT 10H reset
;----------------------------------------------------------------------------;
	GET_EFLAG VIDM				; AL = 00=error(ZF), 01=CGA 40, 10=CGA 80, 11=MDA
	XCHG	AX, DX				; AL = EQUIP_FLAGS, DL = BDA initial video mode
	JNZ	VID_MODE_OK				; jump if mode valid or video option ROM loaded
	MOV	BL, 33H				; Beep 3 long, 3 short
	JMP	HALT_BEEP				; NEAR jump to beep
VID_MODE_OK:
	TEST	AL, MASK VIDM			; is SW1 mode 00?
	JZ	RESET_VIDEO_DONE			; if custom video ROM, skip reset
	DEC	DX
	MOV	AL, 1					; CGA 40x25 color
	JZ	RESET_VIDEO				; ZF if CGA 40
	MOV	AL, 3					; CGA 80x25 color
	DEC	DX					; ZF if CGA 80
	JZ	RESET_VIDEO				; jump if CGA, fall through if MDA
	MOV	AL, 7					; else MDA

;----------------------------------------------------------------------------;
; Clear screen and reset the video display.
;
RESET_VIDEO:
	CBW						; AH = 0 - Set Video Mode in AL
	INT	10H
RESET_VIDEO_DONE:

;----------------------------------------------------------------------------;
; Hello Computer ("just use the keyboard")
;----------------------------------------------------------------------------;
HELLO_WORLD:
	PRINTLN_SZ	VER_BANNER			; display banner

;----------------------------------------------------------------------------;
; Save the initial cursor mode to BDA for hot key and POST display
;
	XOR	BX, BX				; BH = video page 0
	MOV	AH, 3					; CX = power-on cursor
	INT	10H					; DX = and position
	MOV	CURSOR_DEFAULT, CX		; save to BDA for Turbo toggle

			IF POST_SHOW_VER GT 1
;----------------------------------------------------------------------------;
; Display VERSION notice in bottom left
;
	PUSH	DX					; save cursor position
	MOV	DX, 1800H 				; bottom left row = 24, col = 0
	MOV	AH, 2 				; set bottom cursor position 
	INT	10H 					; row = DH, column = DL
	PRINT_SZ VER				; display version
	PRINT_SZ REL_DATE				; display build date
	POP	DX					; restore previous cursor
	MOV	AH, 2 				; reset cursor position
	INT	10H 					; row = DH, column = DL
			ELSE
	PRINT_SZ VER				; display version
	PRINTLN_SZ REL_DATE			; display build date
	CALL	CRLF
			ENDIF

;----------------------------------------------------------------------------;
; Jump over INT 02h fixed ORG to continue...
;
	JMP	SHORT INT_02_AFTER

			IF ARCH_TYPE EQ ARCH_TURBO
;----------------------------------------------------------------------------;
; Toggle Turbo mode on/off
;----------------------------------------------------------------------------;
; Note: some references state that flipping both bit 2 and 3 (0Ch) are
; required, and some only bit 2 (04h). Flipping only bit 2 seems to work fine.
;
; Size: 25 bytes
;
; Clobbers AX, CX
;----------------------------------------------------------------------------;
; NOTE: ORG located here to fill the space taken up by additional 5150 code
;----------------------------------------------------------------------------;
TOGGLE_TURBO PROC
			ASSUME DS:_BDA
	CLI						; interrupts off

			IF TURBO_TYPE EQ TURBO_90H
;----------------------------------------------------------------------------;
; ST-xx Port 90h Turbo switch
; If port 90 == 1, send 2 (0010b) Normal -> Turbo
; If port 90 == 0, send 3 (0011b) Turbo -> Normal
;
	IN	AL, TURBO_CTRL_90H		; read current state
	CMP	AL, 0001b				; is 1 or 0?
	JA	TOGGLE_TURBO_DONE			; exit if register not valid
	OR	AL, 0010b				; add "set" bit
	XOR	AL, 0001b				; flip 2 <=> 3
	OUT	TURBO_CTRL_90H, AL		; write to board

			ELSE
;----------------------------------------------------------------------------;
; Standard PPI B Turbo switch
;
	IN	AL, PPI_B				; read PPI
	XOR	AL, MASK PBTB			; flip turbo bit
	OUT	PPI_B, AL
			ENDIF

	MOV	CX, CURSOR_DEFAULT		; original power-on cursor
			IF TURBO_TYPE EQ TURBO_90H
	CMP	AL, 0011b				; turbo on?
			ELSE
	TEST	AL, MASK PBTB			; turbo bit set?
			ENDIF
	JNZ	TOGGLE_TURBO_CURSOR		; Jump if turbo, use original cursor
	XOR	CH, CH 				; starting scan line 0 ("big cursor")
TOGGLE_TURBO_CURSOR:
	MOV	AH, 1					; Video set cursor
	INT	10H

TOGGLE_TURBO_DONE:
	STI						; Enable interrupts
	RET
TOGGLE_TURBO ENDP
			ENDIF

;
; 1 BYTE HERE
;
BYTES_HERE	INT_02

;----------------------------------------------------------------------------;
; INT 2 - NMI 
;----------------------------------------------------------------------------;
; If NMI / IRQ 2 occurs (a parity or I/O exception), display error type and
; halt. Exit if it was an 8087 exception as that should be intercepted by 
; a user coprocessor exception handler.
;----------------------------------------------------------------------------;
		ORG 0E2C3H
INT_02 PROC
		ASSUME DS:_BDA
	PUSH	AX
	IN	AL, PPI_C 				; get PC0 register
	TEST	AL, 11000000B 			; parity or I/O error?
	JNZ	INT_02_NMI_PAR 			; first, check parity
	POP	AX					; if neither, exit
	IRET						; must have been an 8087 NMI
INT_02_NMI_PAR:
	XOR	AX, AX				; reset video, clear screen
	INT	10H					;  and switch to text video mode
	MOV	SI, OFFSET NMI_ERR_PAR 		; Parity error string
	TEST	AL, 10000000B 			; parity error?
	JZ	INT_02_NMI_HALT
	MOV	SI, OFFSET NMI_ERR_IO 		; otherwise is I/O error
INT_02_NMI_HALT:
	CALL	OUT_SZ 				; display string in CS:SI
	CLI						; ensure interrupts off
	HLT						; halt CPU
INT_02 ENDP

INT_02_AFTER:

;----------------------------------------------------------------------------;
; [18] Setup DS and ES to BDA segment
;----------------------------------------------------------------------------;
			ASSUME DS:_BDA, ES:_BDA
	MOV	AX, SEG _BDA 			; DS and ES to BDA
	MOV	DS, AX
	MOV	ES, AX

;----------------------------------------------------------------------------;
; [37] Setup LPT/COM default timeouts
;----------------------------------------------------------------------------;
	MOV	DI, OFFSET LPT_TIME
	MOV	AX, LPT_TO SHL 8 OR LPT_TO	; LPT timeout values
	STOSW						; write x 4 to BDA
	STOSW
	MOV	AX, COM_TO SHL 8 OR COM_TO	; COM timeout values
	STOSW
	STOSW

POST_DETECT_PORTS:
	MOV	BX, OFFSET EQUIP_FLAGS[1]	; BX set to high byte of EQUIP_FLAGS

;----------------------------------------------------------------------------;
; [38] Detect and enable Game ports
;----------------------------------------------------------------------------;
; Port 201H
; Input: 
;	BX = high byte of EQUIP_FLAGS
;
; Equipment Bit is set if the lower nibble of an I/O port 201h read is zero
; http://www.minuszerodegrees.net/5150_5160/post/IBM%205150%20and%205160%20-%20Bit%2012%20of%20Equipment%20Flag.htm
;----------------------------------------------------------------------------;
POST_DETECT_GAM PROC
	MOV	DX, GAME_CTRL
	IN	AL, DX 				; will be 0FFH if no port
	TEST	AL, 0FH
	JNZ	NO_GAME_PORT
	OR	BYTE PTR [BX], HIGH MASK GAM	; enable Game Port bit
NO_GAME_PORT:
POST_DETECT_GAM ENDP

;----------------------------------------------------------------------------;
; [37] Detect and enable COM ports 1-4
;----------------------------------------------------------------------------;
; Ports 3F8H, 2F8H, 3E8H, 2E8H
; Input:
;	BX = high byte of EQUIP_FLAGS
;	ES, DS = BDA segment
;----------------------------------------------------------------------------;
POST_DETECT_COM PROC
	MOV	CX, 4
	XOR	DI, DI 				; 00H BDA COM1-4 base addresses
	MOV	DX, COM1_IIR			; 03FAH: COM1 Interrupt Ident Reg
COM_DETECT_LOOP:
	IN	AL, DX 				; should only have low 3 bits set
	SUB	DX, 2 				; get base port
	TEST	AL, 11111000B 			; check if any high 5 bits are set
	JNZ	NO_COM_PORT				; if so, not a valid port
	XCHG	AX, DX
	STOSW 					; write I/O port to COM BDA table
	XCHG	AX, DX
	ADD	BYTE PTR [BX], HIGH (1 SHL COM) ; INC COM port count in flags
NO_COM_PORT:
	SUB	DX, 0FEH
	CMP	CL, 3 				; is COM3?
	JNZ	NEXT_COM_PORT
	ADD	DX, 01F0H 				; if so, add 1F0 to get to 3EA again
NEXT_COM_PORT:
	LOOP	COM_DETECT_LOOP
POST_DETECT_COM ENDP

;----------------------------------------------------------------------------;
; [36] Detect and enable LPT ports
;----------------------------------------------------------------------------;
; Ports 3BCH, 378H, 278H
; Input: 
;	BX = high byte of EQUIP_FLAGS
;	CH = 0
;----------------------------------------------------------------------------;
POST_DETECT_LPT PROC
	MOV	DI, OFFSET LPT_ADDR		; 08H BDA LPT1-3 base addresses
	MOV	DX, 03BCH				; start with MDA printer base
	MOV	CL, 3
LPT_DETECT_LOOP:
	MOV	AL, 1011B
	OUT	DX, AL				; send to LPT data port
	INC	DX
	INC	DX					; DX = control port
	INC	AX					; AL = 1100 - Strobe off / init
	OUT	DX, AL				; send to LPT control port
	DEC	DX
	DEC	DX					; DX = data port
	IN	AL, DX				; send to LPT data port
	CMP	AL, 1011B
	JNZ	NO_LPT_PORT
	XCHG	AX, DX
	STOSW 					; store to LPT BDA table
	XCHG	AX, DX
	ADD	BYTE PTR [BX], HIGH (1 SHL LPT) ; INC LPT port count in flags
NO_LPT_PORT:
	DEC	DH 					; DX = DX - 100H
	CMP	CL, 3 				; is 3BCH?
	JNZ	NEXT_LPT_PORT
	ADD	DX, 0BCH 				; if so, add BC to get to 378
NEXT_LPT_PORT:
	LOOP	LPT_DETECT_LOOP
POST_DETECT_LPT ENDP

;----------------------------------------------------------------------------;
; Reset Keyboard Interface
;----------------------------------------------------------------------------;
; http://minuszerodegrees.net/5160/keyboard/5160_keyboard_startup.jpg
;
; KB Status Port 61h high bits:
; 01 - normal operation. wait for keypress, when one comes in,
;		force data line low (forcing keyboard to buffer additional
;		keypresses) and raise IRQ1 high
; 11 - stop forcing data line low. lower IRQ1 and don't raise it again.
;		drop all incoming keypresses on the floor.
; 10 - lower IRQ1 and force clock line low, resetting keyboard
; 00 - force clock line low, resetting keyboard, but on a 01->00 transition,
;		IRQ1 would remain high
;----------------------------------------------------------------------------;
POST_KB_RESET PROC
	MOV	DX, PPI_B 				; DX = PPI port B (61H)
	IN	AL, DX
	AND	AL, NOT (MASK PBKB OR MASK PBKC) ; keyboard clock hold LOW and enable
	OUT	DX, AL				; send to PPI port B
	XCHG	AX, SI				; save modified PPI port B

;----------------------------------------------------------------------------;
; [31] - Set up and clear keyboard buffer
;----------------------------------------------------------------------------;
	MOV	AX, OFFSET KB_BUF 		; AX = initial start of buffer
	MOV	DI, OFFSET KB_BUF_HD 		; DI = buffer head
	STOSW 					; write to head pointer
	STOSW 					; write to tail pointer
	MOV	DI, OFFSET KB_BUF_ST 		; setup buffer start and end
	STOSW
	MOV	AL, LOW OFFSET KB_BUF_END	; (AH already 00)
	STOSW

;----------------------------------------------------------------------------;
; Hold clock low 20+ ms to signal keyboard to reset. Clear and re-enable.
;
	MOV	AL, 30				; I/O delay for at least 20ms
	CALL	IO_DELAY_MS
	XCHG	AX, SI				; restore modified PPI port B

	OR	AL, MASK PBKB OR MASK PBKC	; keyboard enable clock and clear
	OUT	DX, AL				; send to PPI port B
	AND	AL, NOT MASK PBKB			; keyboard enable (clear low)
	OUT	DX, AL				; send to PPI port B

;----------------------------------------------------------------------------;
; Unmask KB interrupt IRQ1
;
	IN	AL, INT_P1 				; get PIC Port 1 INT mask
	XCHG	AX, SI 				; SI = save previous INT mask
	MOV	AL, 11111101B 			; enable only keyboard interrupt
	OUT	INT_P1, AL

;----------------------------------------------------------------------------;
; Check if reset scan code was received
;
; Temporary INT_09_POST interrupt will set 4000H flag on BP
; when IRQ1 is received with successful reset code of 0AAh
;
	STI 						; enable interrupts
KB_RESET_TEST:
	NOP 						; give a little more time
	NOP 						;  and a little more time still
	POST_FLAG_TEST PKI			; KB test flag yet?
	LOOPZ	KB_RESET_TEST			; Loop until KB flag OR CX is 0 (timeout)
	CLI 						; disable interrupts again
	POST_FLAG_FLIP PKI			; invert PKI flag: 1 = error, 0 = success

	IO_DELAY_LONG 				; additional delay, CX = 0

;----------------------------------------------------------------------------;
; Ack scan code, clear keyboard again and check that no scan codes were received
;
	OR	AL, MASK PBKB OR MASK PBKC	; keyboard enable clock and clear
	OUT	DX, AL				; send to PPI port B
	AND	AL, NOT MASK PBKB			; keyboard enable (clear low)
	OUT	DX, AL				; send to PPI port B

	IO_DELAY					; delay for KBC, CX = 0

	IN	AL, PPI_A 				; check KB for extraneous key
	TEST	AL, AL				; AL should be 0
	JZ	KB_HAPPY				; if so, KB is ready
	POST_FLAG_SET PKEY			; otherwise set flag for keyboard error
KB_HAPPY:

;----------------------------------------------------------------------------;
; Disable keyboard for rest of POST
;
	IN	AL, DX
	OR	AL, 11000000B 			; keyboard clock hold off and clear HIGH
	OUT	DX, AL				; send to PPI port B

	XCHG	AX, SI 				; restore interrupt mask register
	OUT	INT_P1, AL

;----------------------------------------------------------------------------;
; Set up the real INT 09H keyboard interrupt handler
;
	MOV	ES, CX 				; ES = IVT seg (CX is 0 from above)
	MOV	DI, OFFSET _INT_09H 		; DI = INT 9H offset in IVT (24H)
	MOV	AX, OFFSET INT_09 		; Vector offset
	STOSW 					; replace in IVT

POST_KB_RESET ENDP

;----------------------------------------------------------------------------;
; Begin Hardware POST Test Results
;----------------------------------------------------------------------------;

	CALL	HIDE_CURSOR				; cursor movement is distracting

;----------------------------------------------------------------------------;
; Display "WARM" or "COLD" boot
;
HELLO_BOOT_TYPE PROC
	MOV	SI, OFFSET POST_WARM		; default to "WARM"
	MOV	BL, POST_CLR_WARM			; attribute to Warm color
	JWB	HELLO_COLD_WORLD			; jump if warm boot
	MOV	SI, OFFSET POST_COLD		; use "COLD"
	MOV	BL, POST_CLR_COLD			; attribute to Cold color
HELLO_COLD_WORLD:
	PUSH	SI					; save WARM/COLD string
	MOV	SI, OFFSET POST_BOOT		; "BOOT" string
	CALL	POST_START_COL_1			; display column label
	POP	SI
	CALL	OUT_SZ				; display WARM or COLD
	POST_COL_END_NL				; end column label
HELLO_BOOT_TYPE ENDP

;----------------------------------------------------------------------------;
; [17] Detect and test conventional memory
;----------------------------------------------------------------------------;
	CALL	DETECT_MEMORY			; detect and display memory count
		IF POST_VIDEO_TYPE NE 1
	CALL	CRLF
		ENDIF

;----------------------------------------------------------------------------;
; [27B] Verify that the 8237 DMA Channel 0 Terminal Count (TC 0) status bit 
; is on. This test is only done on a cold boot.
;----------------------------------------------------------------------------;
	JWB	DMA_STATUS_OK			; skip on warm boot
	IN	AL, DMA_CMD				; verify DMA status register
	TEST	AL, 00000001B			; Channel 0 TC
	JNZ	DMA_STATUS_OK
	POST_FLAG_SET PDMA			; mark in POST error flags
DMA_STATUS_OK:

;----------------------------------------------------------------------------;
; Display Additional Configuration Items such as COM/LPT, CPU, FPU, etc
;----------------------------------------------------------------------------;
	CALL	POST_SYS_CONFIG
	CALL	CRLF
	CALL	SHOW_CURSOR				; re-enable cursor

;----------------------------------------------------------------------------;
; [28] Option ROM scan for other ROMs (storage, etc)
;----------------------------------------------------------------------------;
	MOV	AX, SEG _OPT_ROM			; start at 0C800H
	MOV	DI, OPT_ROM_END 			; end below 0FE00H
	CALL	BIOS_ROM_SCAN

;----------------------------------------------------------------------------;
; [31] Enable interrupts IRQ 0 (system timer) and IRQ 1 (keyboard).
;----------------------------------------------------------------------------;
; Unmask IRQs for Timer (IRQ0), Keyboard (IRQ1) and Floppy (IRQ6)
;----------------------------------------------------------------------------;
	IN	AL, INT_P1 				; get current OCW1/IMR register
	AND	AL, 10111100B 			; unmask IR6, IR1, IR0
	OUT	INT_P1, AL 				; send to A1 (Port 1)
	STI 						; Interrupts now enabled

;----------------------------------------------------------------------------;
; [30] Recalibrate and test seek the floppy drive
;----------------------------------------------------------------------------;
FDC_POST PROC
	XOR	AX, AX 				; AH = reset
	CWD						; DL = start at drive 0
	INT	13H					; Reset the controller
	JC	FDC_POST_CT_ERR
	GET_EFLAG FLP				; AX = # of floppy drives (0 based)
	INC	AX					; fixup 1 based drive count

;----------------------------------------------------------------------------;
; Display FDC POST drive count column
;
	POST_COL_1 POST_FDD, POST_CLR_VAL2	; display FDC column label
	CALL	OUT_DECU				; display decimal value in AX
	POST_COL_END

	XCHG	AX, CX				; CX = number of floppy drives
FDC_POST_TESTS_DRV:
	CALL	POST_FD_TEST_DRIVE		; test drive
	JC	FDC_POST_DRV_ERR			; jump if error
	INC	DX					; DL = next drive
	LOOP	FDC_POST_TESTS_DRV
	JMP	SHORT FDC_POST_TESTS_DONE	; tests successful

FDC_POST_CT_ERR:					; POST: controller error
	POST_FLAG_SET PFDC			; mark in POST error flags
	JMP	SHORT FDC_POST_TESTS_DONE

FDC_POST_DRV_ERR:					; POST: drive error
	POST_FLAG_SET PFSK			; mark in POST error flags

FDC_POST_TESTS_DONE:
FDC_POST ENDP

;----------------------------------------------------------------------------;
; Detect and show hard drive info
;----------------------------------------------------------------------------;
HDD_POST PROC
	MOV	DL, 80H				; reset C: (80H)
	MOV	AH, 0
	INT	13H
	JC	HDD_POST_NONE			; if CF, no HD or reset failure
	MOV	DL, 80H
	CALL	GET_DISK_PARAMS			; return # HD's in DX
	JC	HDD_POST_NONE

HDD_POST_COUNT PROC
;----------------------------------------------------------------------------;
; Display HDD POST drive count column
;
	POST_COL_2	POST_HDD, POST_CLR_VAL2	; display HDC column label

	PUSH	DX					; save drive count
	XCHG	AX, DX				; AL = drive count
	CALL	NIB_HEX				; write as hex to console (clobs AX)
	POST_COL_END_NL				; end column
	POP	CX					; CX = drive count
	JCXZ	HDD_POST_DONE			; reset passed but 0 drives

HDD_POST_COUNT ENDP

;----------------------------------------------------------------------------;
; Display HDD drive letter(s) and size(s)
;	
	MOV	DL, 80H				; start with drive 80H (C:)
HDD_POST_SHOW_LOOP:
	CALL	SHOW_DISK_PARAMS			; show drive letter and geometry
	INC	DX					; move to next drive
	LOOP	HDD_POST_SHOW_LOOP
	JMP	SHORT HDD_POST_DONE

HDD_POST_NONE:
	CALL	CRLF
HDD_POST_DONE:
HDD_POST ENDP

;----------------------------------------------------------------------------;
; [39] Clear and enable I/O and parity NMI's
;----------------------------------------------------------------------------;
	CALL	NMI_RESET				; reset NMI flags

ENABLE_NMI:
	MOV	AL, 10000000b			; AL = 80H to enable NMI
	OUT	NMI_R0, AL				; write to controller

;----------------------------------------------------------------------------;
; Enable keyboard
;
	CALL	KB_BUF_CLEAR			; clear any stray keys in buffer
	IN	AL, PPI_B 				; AL = PB0 flags
	AND	AL, NOT MASK PBKB			; keyboard clear LOW (enable KB)
	IO_DELAY_SHORT
	OUT	PPI_B, AL				; send to PPI port B

;----------------------------------------------------------------------------;
; Check for POST errors and clear warm boot flag
;
	XOR	AX, AX				; AX = 0
	MOV	WARM_FLAG, AX			; clear warm boot flag in BDA
	AND	BP, NOT MASK WARM			; remove warm boot flag
	JZ	POST_OK				; if no errors, go ahead and boot

;----------------------------------------------------------------------------;
; Display any POST errors
;
POST_ERROR:
	CALL	MEEPMEEP				; alert that there was an error
	PRINT_SZ POST_ERR
	MOV	AX, BP
	CALL	WORD_HEX				; display POST error value
	CALL	CRLF
	CALL	POST_ERROR_MSG			; display POST error messages
	PRINT_SZ NL_ANY_KEY			; "Any key" string
	XOR	AX, AX				; wait for key press
	INT	16H
	CALL	CRLF

POST_OK:
;----------------------------------------------------------------------------;
; [40] DO BOOTSTRAP!
;----------------------------------------------------------------------------;
CLEAR_POST_SCREEN:
	MOV	BH, 7					; attribute fill for on blank line
			IF POST_CLS EQ 1		; clear the whole screen
	MOV	AX, 700H OR 25			; AH = 7, scroll down 25 lines
	MOV	CX, 0 SHL 8 OR 0			; upper left row 0, column 0

			ELSE				; clear only the lower two rows
	MOV	AX, 700H OR 2			; AH = 7, scroll down 2 lines
	MOV	CX, 23 SHL 8 OR 0			; upper left row 23, column 0
			ENDIF

	MOV	DX, 25 SHL 8 OR 80		; lower right row 25, column 80
	INT	10H

			IF POST_CLS EQ 1		; set cursor to top of screen
	MOV	AH, 2					; set cursor position
	MOV	BH, 0					; video page 0
	CWD						; row = 0, col = 0
	INT	10H
			ENDIF

	CALL	BEEP 					; beep to signify POST test is done
			IF POST_GLADOS EQ 1
	PRINT_SZ BOOT_BEGIN			; Starting GLaDOS...
			ELSE
	CALL	CRLF
			ENDIF

;----------------------------------------------------------------------------;
; Check IPL (has bootable disk drive) switch on MB and boot to BASIC if not
; This is most likely unnecessary.
;
	;TEST_EFLAG IPL				; Has bootable drive? (IPL flag/switch set)
	;XOR	AX, AX				; force boot to BASIC
	;JZ	TRY_INT18				;

;----------------------------------------------------------------------------;
; Attempt to IPL three times from drive 0h. If failure, call INT 18h / ROM BASIC.
;
	CWD						; IPL from drive 0 A: (DL = 0h)
	MOV	CX, 3 				; retry IPL 3 times
BOOT_RETRY:
	PUSH	CX					; save retry counter
	INT	19H
	IO_DELAY_LONG
	POP	CX					; restore retry counter
	LOOP	BOOT_RETRY
TRY_INT18:
	INT	18H					; ROM BASIC or boot failure
	CLI						; INT 18h should never return...
	HLT						;  but halt just in case

POWER_ON ENDP

;----------------------------------------------------------------------------;
;
; END OF BIOS POST/BOOTSTRAP
;
;----------------------------------------------------------------------------;

STRINGS PROC

;----------------------------------------------------------------------------;
; Banner Strings
;
BANNER_STRINGS PROC

					IF POST_GLADOS EQ 1
BOOT_BEGIN		DB	CR,LF
			DB	'Starting GLaDOS...'
NL2_Z			DB	LF					; two NL's, null term'd
					ENDIF
NL_Z			DB	CR,LF,0				; one NL, null term'd

BOOT_FAIL		DB	'Disk Boot Fail. You monster.'
NL2_ANY_KEY		DB	LF
NL_ANY_KEY		DB	CR,LF
ANY_KEY		DB	'Press the Any Key.'
				IF ARCH_TYPE NE ARCH_5150	; omit for space reasons
			DB	'..'
				ENDIF
			DB	 0

BANNER_STRINGS ENDP

NMI_STRINGS PROC
NMI_ERR_PAR		DB	'PARITY', 0			; NMI Parity Error
NMI_ERR_IO		DB	'NMI', 0			; NMI I/O Error
NMI_STRINGS ENDP

POST_STRINGS PROC
;----------------------------------------------------------------------------;
; POST Test Strings
;
POST_BOOT		DB	'Boot', 0
POST_WARM		DB	'WARM', 0
POST_COLD		DB	'COLD', 0
POST_CPU		DB	'CPU',  0
POST_8088		DB	'8088', 0
POST_V20		DB	'V20',  0
POST_FPU		DB	'FPU',  0
POST_8087		DB	'8087', 0
POST_LPT		DB	'LPT',  0
POST_COM		DB	'COM',  0
POST_FDD		DB	'FDD',  0
POST_HDD		DB	'HDD',  0
POST_HD		DB	':',    0
POST_MB		DB	' MB (',0
POST_NONE		DB	'None', 0
POST_MEMORY		DB	CR, 'RAM', 0		; RAM Memory test
				IF POST_SHOW_VER GT 2
POST_KB_OK		DB	' KB OK',0
				ELSE
POST_KB_OK		DB	'KB',0
				ENDIF
POST_LSEP		DB	POST_L, 0
POST_RSEP		DB	POST_R, 0

;----------------------------------------------------------------------------;
; POST Error Strings
;
POST_ERR		DB	CR,LF, 'POST '		; POST Error
POST_ERR_ERR	DB	'Error ', 0			; Error
POST_ERR_PKI	DB	'KB Init', 0		; Reset returned non-success "301"
POST_ERR_PKEY	DB	'Key Stuck', 0		; Reset did not clear KBC
POST_ERR_PFDC	DB	'FDC', 0			; General FD init failure
POST_ERR_PFSK	DB	'FD Seek', 0		; Seek test failure
POST_ERR_PDMA	DB	'DMA', 0			; DMA TC0 error
POST_ERR_PMEM	DB	'RAM', 0
;POST_ERR_PHDC	DB	'HD', 0			; General HD init failure

;----------------------------------------------------------------------------;
; POST String Vectors - indexed by PFLAGS
;
POST_ERRORS LABEL WORD
	DW	OFFSET POST_ERR_PKI		; PKI  : Keyboard Interrupt Error
	DW	OFFSET POST_ERR_PKEY		; PKEY : Keyboard Key Stuck
	DW	OFFSET POST_ERR_PFDC		; PFDC : FDC Init Failure
	DW	OFFSET POST_ERR_PFSK		; PFSK : FDC Seek Test Failure
	DW	OFFSET POST_ERR_PDMA		; PDMA : DMA TC0 Error
	DW	OFFSET POST_ERR_PMEM		; PMEM : RAM Error
	;DW	OFFSET POST_ERR_PHDC		; PHDC : HDC Error
L_POST_ERRORS	EQU	($-POST_ERRORS)/SIZE POST_ERRORS

POST_STRINGS ENDP

STRINGS ENDP

;============================================================================;
;
;		        * * *   P R O C s  &  I N T s  * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; Display all POST messages
;----------------------------------------------------------------------------;
; See PFLAGS
; Output: BP = 0
; Size: 28 bytes
;----------------------------------------------------------------------------;
POST_ERROR_MSG PROC
	SHL	BP, 1
	JZ	POST_ERROR_MSG_EXIT		; no errors?
	MOV	CX, L_POST_ERRORS			; # of available POST error messages
	MOV	SI, OFFSET POST_ERRORS
POST_ERROR_MSG_LOOP:
	LODS	WORD PTR CS:[SI]			; AX = next message offset
	RCL	BP, 1
	JNC	POST_ERROR_MSG_NEXT		; no flag
	TEST	AX, AX
	JZ	POST_ERROR_MSG_NEXT		; no string
	XCHG	AX, SI
	PRINTLN_SZ SI				; write string with CRLF
	XCHG	AX, SI
POST_ERROR_MSG_NEXT:
	LOOP	POST_ERROR_MSG_LOOP
POST_ERROR_MSG_EXIT:
	RET
POST_ERROR_MSG ENDP

;----------------------------------------------------------------------------;
; Scan, checksum and call BIOS ROMs
;----------------------------------------------------------------------------;
; Input:
;	AX = starting segment
;	DI = ending segment
;
; Note: ROM init's can clobber any or all registers so important to save
; any that are used here between calls.
;
; Clobbers: AX, SI, ES (anything else the ROM might, except for DS and BP)
; Size: 56 bytes
;----------------------------------------------------------------------------;
BIOS_ROM_SCAN PROC
		ASSUME ES:_BDA
	PUSH	BP					; some option ROMs may clobber BP
	PUSH	DS					; call preserve DS
	MOV	DS, AX 				; DS = starting segment
CHECK_ROM:
	MOV	AX, SEG _BDA 			; ES = 0040H (BIOS BDA segment)
	MOV	ES, AX				; re-set ES for each ROM call
	PUSH	DS					; save current DS segment
	XOR	SI, SI 				; reset offset to 0
	LODSW 					; AX = first word
	CMP	AX, MAGIC_WORD			; is it an extension ROM? (0AA55H)
	JNZ	NEXT_ROM 				; if not, check next 2K block
FOUND_ROM:
	LODSB						; AL = ROM size in 512B blocks
	TEST	AL, AL				; is size "reasonable"?
	JS	NEXT_ROM				; if not, skip
	CALL	ROM_CHECKSUM 			; checksum ROM at DS:0, size AL
	JNZ	NEXT_ROM				; if NZ, checksum failed, skip it

;----------------------------------------------------------------------------;
; Call Option ROM's BIOS init routine
;
	PUSH	DI					; save ending segment
	MOV	DI, OFFSET ROM_INIT_SS		; BDA = temp location for FAR CALL
	MOV	ES:[DI], SI				; Init vector offset (always 3)
	MOV	ES:[DI+2], DS			; Init vector segment
	CALL	DWORD PTR ES:[DI]			; CALL Option ROM init
	POP	DI					; restore ending segment
NEXT_ROM:
	POP	AX					; restore current DS segment
	ADD	AX, 80H				; next 2k boundary
	MOV	DS, AX
	CMP	AX, DI 				; end of extension ROM regions?
	JB	CHECK_ROM 				; if not, check next
ROM_SCAN_DONE:
	POP	DS 					; restore regs
	POP	BP
	RET
BIOS_ROM_SCAN ENDP

;----------------------------------------------------------------------------;
; DETECT_MEMORY - Detect, test and clear RAM
;----------------------------------------------------------------------------;
; Attempt to determine how much RAM is installed using MEM_ADDR_TEST for 
; more reliable memory detection.
;
; Output: Memory count to console
;
; NOTE: Testing first two bytes of each block is problematic:
; http://minuszerodegrees.net/5160/problems/5160_known_problems_issues.htm
; http://minuszerodegrees.net/5160/problems/5160_ram_size_flaw.htm
;----------------------------------------------------------------------------;
DETECT_MEMORY PROC
			ASSUME DS:_BDA, ES:NOTHING
	PUSH	ES
	PUSH	DS
	MOV	AX, SEG _BDA
	MOV	DS, AX
			IF ARCH_TYPE EQ ARCH_5150
	MOV	AX, MEM_SZ_PC			; SW2 RAM size in KB
	MOV	CL, 4					; shift counter
	SHR	AX, CL				; Number of 16KB RAM blocks
	XCHG	AX, CX				; CX = 16KB RAM blocks
	DEC	CX					;  after first 16K block
			ELSE
	MOV	CX, (MAX_RAM SHR 4) - 1		; Max number of 16KB RAM blocks
							; (ex: 640K / 16K = 40)
			ENDIF
	MOV	DX, 400H				; Start at second 16KB block
	MOV	ES, DX				; ES = seg 0400H
BLOCK_LOOP:
	CALL	MEM_ADDR_TEST			; address test on 16KB RAM block at ES
	JNZ	BLOCK_LOOP_DONE			; exit loop if test failed
	ADD	DH, 4					; add 400h paras (4000h bytes)
	MOV	ES, DX
	LOOP	BLOCK_LOOP				; loop until MAX_RAM
BLOCK_LOOP_DONE:

;----------------------------------------------------------------------------;
; Test and clear RAM, show memory count
;
; Input:
;	ES = highest memory segment "detected"
;	DX = size of memory in paras
;
			IF CPU_TYPE	EQ CPU_V20
	SHR	DX, 6					; V20: shift right 6 times to get K
			ELSE
	MOV	CL, 6					; 8088: shift right 6 times to get K
	SHR	DX, CL
			ENDIF
	MOV	MEM_SZ_KB, DX 			; save to BDA
	MOV	DX, ES				; DX = highest RAM segment detected
	XOR	BX, BX				; BX = 0, segment and memory test counter
	MOV	ES, BX				; start at segment 0000
ZERO_ALL_RAM:
	ADD	BX, 16				; increment Memory count value
	CALL	SHOW_MEM_TEST			; show "Memory:  xxxKB OK", BX = size in KB
	MOV	AX, ES				; AX = last segment tested
	ADD	AX, 0400H				; move to next segment/block
	CMP	AX, DX				; is last segment of RAM?
	JNB	DONE_ZERO_ALL_RAM			; exit if end
	MOV	ES, AX				; ES = last segment tested
	JWB	ZERO_ALL_START			; skip long tests on warm boot

;----------------------------------------------------------------------------;
; Perform memory checks on this block
;
TEST_MEM_LONG:
	CALL	NMI_RESET				; clear NMI/parity flags
	CALL	MEM_TEST				; read/write test on 16KB RAM block at ES
	JNZ	DETECT_MEMORY_ERR
	XCHG	AX, DX				; save AX
	IN	AL, PPI_C				; read PPI Port C
	AND	AL, MASK PCPE OR MASK PCIE	; was there parity or NMI error?
	XCHG	AX, DX				; DL = parity error flag(s)
	JNZ	DETECT_MEMORY_ERR			; jump if parity error

;----------------------------------------------------------------------------;
; Write 0's to all memory in this block
;
ZERO_ALL_START:
	XOR	AX, AX 				; write zeros
	MOV	CX, 02000H				; count 8K WORDs
	XOR	DI, DI				; DI = beginning of segment
	REP	STOSW 				; write zero to next 16KB
	JMP	SHORT ZERO_ALL_RAM
DONE_ZERO_ALL_RAM:
	POP	DS
	POP	ES
	RET

;----------------------------------------------------------------------------;
; Compare the result read from memory to the expected results to determine
; which bit(s) did not match.
;
; Error will be displayed as SEG:OFF BBBB.
;
; - SEG: location/bank in memory of the failed IC, which can be calculated
;   using the following:
;   http://minuszerodegrees.net/5160/ram/5160_ram_201_error_breakdown.jpg
; - OFF: offset where the failure occurred
; - BBBB: bit pattern difference between what was expected and what was 
;   read. This should reveal which IC in that bank failed.
;
DETECT_MEMORY_ERR:
	POST_FLAG_SET PMEM			; set POST Memory error flag
	CALL	CRLF					; start on new line
	POST_COL_1	POST_ERR_ERR, RED
	DEC	DI					; move back to last address
	DEC	DI
	XOR	AX, ES:[DI]				; determine incorrect bit(s)
	XCHG	AX, DI				; DI = bit pattern, AX = err offset
	MOV	BX, ES				; segment of error
	CALL	DWORD_HEX				; write address
	CALL	SPACE
	TEST	DL, DL				; was there a parity error?
	JZ	DETECT_MEMORY_ERR_2		; jump if not
	PRINT_SZ NMI_ERR_PAR			; print 'PARITY'
	JMP	SHORT DETECT_MEMORY_ERR_DONE
DETECT_MEMORY_ERR_2:
	XCHG	AX, DI				; restore failed bit pattern
	CALL	WORD_HEX
DETECT_MEMORY_ERR_DONE:
	POST_COL_END
	JMP	SHORT DONE_ZERO_ALL_RAM

DETECT_MEMORY ENDP

			IF POST_VIDEO_TYPE EQ 1
;----------------------------------------------------------------------------;
; Display Video Type
;----------------------------------------------------------------------------;
; Size: 109 bytes
;----------------------------------------------------------------------------;
POST_SYS_VIDEO PROC
	POST_COL_2	POST_VIDEO, POST_CLR_VAL1	; display "Video" left column
	MOV	SI, OFFSET POST_NONE			; default to "None"

;----------------------------------------------------------------------------;
; Check if INT 10 is using the BIOS. If so, must be CGA or MDA.
;
; Necessary to check both segment and offset? (would save a few bytes if not)
;
	PUSH	DS
	XOR	AX, AX				; AX = SEG _IVT
	MOV	DS, AX				; set IVT segment for LDS
			ASSUME DS:_IVT
	LDS	AX, DWORD PTR _INT_10H		; if BIOS, DS = 0F000H, AX = 0F065H
	CMP	AX, OFFSET INT_10			; is offset the BIOS IRR for INT 10?
	MOV	AX, DS				; save for next compare
	POP	DS					; restore DS
			ASSUME DS:_BDA
	JNE	CHECK_VGA				; jump to VGA check if not
	MOV	BX, CS				; AX = BIOS code segment
	CMP	AX, BX				; is segment BIOS?
	JNE	CHECK_VGA

;----------------------------------------------------------------------------;
; Read BDA for video type
;
BIOS_VIDEO:
	CALL	INT_10_F				; AL = current video mode
	MOV	SI, OFFSET POST_MDA		; default "MDA"
	CMP	AL, 7					; is MDA mode 7?
	JE	POST_SYS_VIDEO_DONE
	MOV	SI, OFFSET POST_CGA		; otherwise "CGA"
	JMP	SHORT POST_SYS_VIDEO_DONE

;----------------------------------------------------------------------------;
; Check if VGA
; stanislavs.org/helppc/int_10-1a.html
;
CHECK_VGA:
	MOV	AX, 1A00H				; AH = 1AH, get video display
	INT	10H					; BL = display type
	CMP	AL, 1AH				; is VGA?
	JNE	CHECK_EGA				; jump if not VGA
	MOV	SI, OFFSET POST_VGA		; is "VGA"
	JMP	SHORT POST_SYS_VIDEO_DONE

;----------------------------------------------------------------------------;
; Check if EGA
; stanislavs.org/helppc/int_10-12.html
;
CHECK_EGA:
	MOV 	AH, 12H
	MOV	BL, 10H				; return video configuration
	INT	10H
	CMP	BL, 10H				; check if param hasn't changed
	JE	POST_SYS_VIDEO_DONE		; jump if not EGA
	MOV	SI, OFFSET POST_EGA		; is "EGA"

POST_SYS_VIDEO_DONE:
	CALL	OUT_SZ				; display detected video adapter
	POST_COL_END_NL
	RET

POST_VIDEO		DB	'Video', 0
POST_VGA		DB	'VGA', 0
POST_EGA		DB	'EGA', 0
POST_CGA		DB	'CGA', 0
POST_MDA		DB	'MDA', 0

POST_SYS_VIDEO ENDP
				ENDIF

;
; 14 BYTES HERE
;
BYTES_HERE	INT_19

;----------------------------------------------------------------------------;
; INT 19 - Bootstrap Loader
;----------------------------------------------------------------------------;
; IPL: track 0, sector 1 is loaded into address 0:7C00 and control 
; is transferred.
;
; Input:
; 	DL = physical drive where boot sector is located (00=A:,80h=C:)
; Output:
;	Transfer control to bootable MBR if success
;	IRET if failure
;
; Clobbers AX, BX, CX, DH, DI, DS, ES
;----------------------------------------------------------------------------;
		ORG 0E6F2H
INT_19 PROC
			ASSUME DS:_IPL_SEG, ES:_IPL_SEG
	STI						; enable interrupts
	CLD						; clear direction for STOS
	XOR	CX, CX				; CX = 0
	MOV	DS, CX				; DS = IPL Segment (0000)
	MOV	ES, CX				; ES = IPL Segment (0000)
	MOV	DI, OFFSET _INT_1EH		; INT 1E vector table address
	MOV	AX, OFFSET INT_1E 		; INT 1E jump address
	STOSW
	MOV	AX, CS				; INT 1E jump segment
	STOSW
INT_19_READ_MBR:
	XCHG	AX, CX				; AH = 0 (reset)
	INT	13H					; reset disk 0
	JC	INT_19_IPL_FAIL			; exit if error
	MOV	AX, 0201H				; AH = 2 (read), AL = 1 sector
	MOV	BX, OFFSET IPL_TOP		; ES:BX = IPL boot sector offset
	MOV	CX, 0001H				; CH = cyl 0, CL = sec 1
	XOR	DH, DH 				; DH = head 0	
	INT	13H					; read 1 sector into ES:BX
	JC	INT_19_IPL_FAIL			; exit if error
	CMP	IPL_ID, MAGIC_WORD		; verify bootable MBR signature
	JNZ	INT_19_IPL_FAIL			; jump if MBR not bootable
	JMP 	FAR PTR IPL_TOP 			; jump to IPL segment and boot!
INT_19_IPL_FAIL:
	IRET
INT_19 ENDP

;----------------------------------------------------------------------------;
; V20 CPU Test ver 2
;----------------------------------------------------------------------------;
; Detect if CPU is V20 or 808x.
; Output:
;	ZF = 1 if V20, ZF = 0 if 8088
;
; Clobbers AX
;
; This uses the "undefined behavior" that AAD imm is always AAD 0AH
;----------------------------------------------------------------------------;
CPU_IS_V20 PROC
	MOV	AX, 0101H			; Attempt to "pack" bytes into nibbles
	DB	0D5H, 10H			; AAD	10H
	CMP	AL, 0BH			; result is 0Bh if V20, 11h if x86
	RET
CPU_IS_V20 ENDP

;----------------------------------------------------------------------------;
; Reset NMI enable flags
;----------------------------------------------------------------------------;
; Output:
;	AL = current PPI B flags
;----------------------------------------------------------------------------;
NMI_RESET PROC
	IN	AL, PPI_B				; read current flags
	OR	AL, MASK PBIO OR MASK PBPC	; parity, I/O flags high (disable)
	OUT	PPI_B, AL				; write to PPI
;	NOP						; allow additional settle time
	XOR	AL, MASK PBIO OR MASK PBPC	; flags low (enable)
	OUT	PPI_B, AL				; write to PPI
	RET
NMI_RESET ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	INT_14

;----------------------------------------------------------------------------;
; INT 14 - BIOS COM Port Services
;----------------------------------------------------------------------------;
;	INT 14,0  Initialize serial port parameters
;	INT 14,1  Send/write character in AL
;	INT 14,2  Receive/read character in AL
;	INT 14,3  Get Serial port status
;
; All functions have:
;	  AH = function number
;	  AL = character to send or receive
;	  DX = zero based RS232 card number
;
; All registers call-preserved (except AX)
;----------------------------------------------------------------------------;
; Ref:
; https://stanislavs.org/helppc/int_14.html
;----------------------------------------------------------------------------;
		ORG 0E739H
INT_14 PROC
			ASSUME DS:_BDA
	STI 						; enable interrupts
	PUSH	CX 					; call-preserve CX
	MOV	CX, 3 				; will use this 3 in multiple places
	CMP	DX, CX				; is less than 4?
	JA	INT_14_EXIT 			; if not, exit
	PUSH	DI 					; call-preserve registers used
	PUSH	BX	
	PUSH	DX
	PUSH	DS
	MOV	DI, SEG _BDA 			; DS = BDA
	MOV	DS, DI
	MOV	DI, DX 				; DI = COM port index (0-3)
	SHL	DI, 1 				; convert to word index
	MOV	DX, [DI] 				; DX = 3F8/2F8 base port address
	SHR	DI, 1 				; back to byte index (cheaper than PUSH/POP)
	TEST	DX, DX 				; is port index valid (detected)?
	JZ	INT_14_DONE 			; if not, exit
	CMP	AH, CL				; check function number (CL = 3)
	JG	INT_14_DONE				; > 3? Not valid
	JZ 	INT_14_3	 			; = 3 then status
	DEC	AH 					; AH--
	JG	INT_14_2 				; = 2 then read
	JZ	INT_14_1 				; = 1 then write
							; otherwise fall through to init

;----------------------------------------------------------------------------;
; INT 14,0  Initialize serial port parameters
;----------------------------------------------------------------------------;
; https://stanislavs.org/helppc/int_14-0.html
; https://stanislavs.org/helppc/8250.html
;----------------------------------------------------------------------------;
; Baud rate divisor table:
;	0 (000) = 110 baud -> 417H	|	4 (100) = 1200 baud -> 60H
;	1 (001) = 150 baud -> 300H	|	5 (101) = 2400 baud -> 30H
;	2 (010) = 300 baud -> 180H	|	6 (110) = 4800 baud -> 18H
;	3 (011) = 600 baud -> 0C0H	|	7 (111) = 9600 baud -> 0CH
;
; Formula:
;	if (baud == 110) then
; 		divisor = 417H
;	else
;		divisor = 600H >> index
;----------------------------------------------------------------------------;
; Input:
;	DX = base port address
;	AL = port params
;	CX = 3 (from earlier)
;----------------------------------------------------------------------------;

INT_14_0 PROC
;----------------------------------------------------------------------------;
; Set baud rate
;
	MOV	DI, DX 			; DX = 3F8/2F8 base port
	ADD	DX, CX			; DX = 3FB/2FB - Line Control Register (LCR), CX = 3
	XCHG	AX, BX			; save port params to BL
	MOV	AL, 10000000B 		; set baud rate divisor (DLAB); 0 = RBR, THR or IER
	OUT	DX, AL 			; write to 3FB/2FB (LCR)
	XCHG	AX, BX 			; restore port params to AL
	XOR	AH, AH 			; clear AH for shift
	SHL	AX, CL 			; AH = baud rate, CL = 3
	SHR	AL, CL 			; AL = flags
	MOV	BX, 417H 			; divisor for 110 baud
	MOV	CL, AH 			; CL = shift counter or 0 for 110 baud (CH = 0)
	JCXZ	INT_14_0_SET_BAUD		; Jump if 110 baud
	MOV	BX, 600H 			; BX = divisor base (see above formula)
	SHR	BX, CL			; divisor = 600H >> CL
INT_14_0_SET_BAUD:
	XCHG	DX, DI 			; DX = 3F8/2F8, DI = 3FB/2FB (4)
	XCHG	AX, BX 			; AL = Divisor LSB, AH = Divisor MSB (4)
	OUT	DX, AL 			; 3F8 - Baud Rate Divisor LSB if bit 7 of LCR
	MOV	AL, AH 			; AL = Divisor MSB (2)
	INC	DX	 			; DX = 3F9/2F9 (3)
	NOP 					; wait a few more clocks just in case (3)
	OUT	DX, AL			; DX = 3F9 - Baud Rate Divisor MSB (if bit 7 of LCR)
;----------------------------------------------------------------------------;
; Set parity, stop and word bits
; 
INT_14_0_SET_PSW:
	XCHG	AX, BX 			; AL = parity, stop and word bits (4)
	XCHG	DX, DI 			; DX = 3FB/2FB, DI = 3F9/2F9 (4)
	OUT	DX, AL			; set parity, stop and word bits
	XCHG	DX, DI 			; DX = 3F9/2F9, DI = 3FB/2FB (4)
;----------------------------------------------------------------------------;
; Disable IER
;
	XOR	AX, AX 			; AL = 0 (3)
	OUT	DX, AL			; DX = 3F9 - Interrupt Enable Register (IER) disabled
	DEC	DX 				; DX = 3F8 (3)

;----------------------------------------------------------------------------;
;	INT 14,3  Get Serial port status
;----------------------------------------------------------------------------;
; In:
; 	DX = base port address
; return:
;	AH = port status
;	AL = modem status
;----------------------------------------------------------------------------;
INT_14_3 PROC
	ADD	DX, 5 			; DX = 3FD/2FD LSR - Line Status Register
	IO_DELAY_SHORT 			; delay for I/O
	IN	AL, DX 			; get line/port status 
	XCHG	AH, AL 			; save to AH
	INC	DX 				; DX = 3FE/2FE MSR - Modem Status Register
	IO_DELAY_SHORT 			; delay for I/O
	IN	AL, DX 			; get modem status 
INT_14_3 ENDP

INT_14_DONE PROC
	POP	DS 				; restore all registers...
	POP	DX
	POP	BX
	POP	DI
INT_14_EXIT PROC
	POP	CX
	IRET
INT_14_EXIT ENDP
INT_14_DONE ENDP

INT_14_0 ENDP

;----------------------------------------------------------------------------;
; INT 14, 1 - Send/write character in AL
;----------------------------------------------------------------------------;
; In:
; 	DX = base port address
;	BL = port timeout
;----------------------------------------------------------------------------;
INT_14_1 PROC
	PUSH	DX 				; save base port
	PUSH	AX
	ADD	DX, 4 			; DX = 3FC/2FC - Modem Control Register
	MOV	AL, 0011B 			; activate DTR & RTS
	OUT	DX, AL			; set DTR or RTS
	INC	DX
	INC	DX 				; DX = 3FE - Modem Status Register
	MOV	BX, 3020H 			; BH = line (THRE), BL = modem (DSR/CTS)
	PUSH	SI
	CALL	INT_14_POLL
	POP	SI
	POP	BX
	MOV	AL, BL 			; AL = output char
	POP	DX 				; restore base port
	JNZ	INT_14_RW_ERR		; Jump if port timeout
	OUT	DX, AL			; 
	JMP	SHORT INT_14_DONE
INT_14_RW_ERR:
	OR	AH, 10000000B		; set error bit
	JMP	SHORT INT_14_DONE
INT_14_1 ENDP

;----------------------------------------------------------------------------;
; INT 14, 2 - Receive/read character in AL
;----------------------------------------------------------------------------;
; In:
;	DX = base port address
;	BL = port timeout
; Out:
;	AH = port status
;	AL = character read
;	NZ = timeout or failure occurred
;
; Clobbers: BX
;----------------------------------------------------------------------------;
INT_14_2 PROC
	PUSH	DX 				; save base port
	ADD	DX, 4 			; DX = 3FC/2FC - Modem Control Register
	MOV	AL, 0001B 			; activate DTR & RTS
	OUT	DX, AL			; set DTR or RTS
	INC	DX
	INC	DX 				; DX = 3FE/2FE - Modem Status Register
	MOV	BX, 2001H  			; BH = modem (DSR), BL = line (data ready)
	PUSH	SI 				; call-preserve SI 
	CALL	INT_14_POLL 		; poll both registers in sequence
	POP	SI
	POP	DX 				; restore base port
	AND	AH, 00011110B 		; include only error bits in port status
	IN	AL, DX			; read char from buffer
	JMP	SHORT INT_14_DONE
INT_14_2 ENDP

;----------------------------------------------------------------------------;
; INT 14 - Poll line then modem status registers
;----------------------------------------------------------------------------;
; In:
;	DI = port index (0 based byte)
; 	DX = 3FE Modem Status Register
;	BL = line status expected masked
;	BH = modem status expected masked
; Out:
;	AH = port status
;	DX = 3FD Line Status Register
;	NZ = timeout or failure occurred
;
; Clobbers: AX, CX, SI
;----------------------------------------------------------------------------;
INT_14_POLL PROC
	CALL	INT_14_POLL_PORT 		; first poll modem status
	JNZ	INT_14_POLL_DONE  	; jump if ZF = 0, timeout or failure occurred
	XCHG	BH, BL 			; BH = line status
	DEC	DX				; DX = 3FD Line Status Register (LSR)
INT_14_POLL_PORT:
	XOR	AX, AX			; clear high byte of AX for move to SI
	XOR	CX, CX			; reset poll loop counter
	MOV	AL, COM_TIME[DI]		; AL = port timeout
	XCHG	AX, SI 			; SI = port timeout
INT_14_POLL_LOOP:
	IN	AL, DX 			; check port status
	MOV	AH, AL 			; save to AH
	AND	AL, BH 			; mask result bits
	CMP	AL, BH 			; did it match expected result?
	JZ	INT_14_POLL_DONE
	LOOP	INT_14_POLL_LOOP		; poll port 65,535 * timeout times
	DEC	SI 				; 
	JNZ	INT_14_POLL_LOOP		; Jump if timeout not expired
INT_14_POLL_DONE:
	RET
INT_14_POLL ENDP

INT_14 ENDP

;----------------------------------------------------------------------------;
;  Get Hard Drive Parameters
;----------------------------------------------------------------------------;
;  Input:
;	DL = drive number
;  Return:
; 	CF if Error
;	AL = number of heads (AX if no error)
; 	AH = return code
;	BX = last cylinder
; 	CX = logical last index of sectors/track
;	DX = number of hard disk drives (all)
;----------------------------------------------------------------------------;
GET_DISK_PARAMS PROC
	MOV	AH, 8 			; Get Drive in DL Parameters: 
	INT	13H				;  CH = Last cyl, CL = # cylinders
						;  DH = heads, DL = # drives
						;  ES:DI = drive table
	JC	_GET_PARAMS_ERR 		; if error, exit
	MOV	BX, CX 			; BX = last cylinder
	XCHG	BH, BL 			; swap words
	ROL	BH, 1 			; rotate high two bits into low bits
	ROL	BH, 1
	AND	BH, 11B			; BX = cylinder (10 bits)
	AND	CX, 00111111B		; CX = logical last index of sectors/track
	MOV	AL, DH
	INC	AX				; convert heads to 1 index (count)
	INC	BX				; convert cylinders to 1 index
	XOR	DH, DH			; clear high byte of DX, CF = 0
_GET_PARAMS_ERR:
	RET
GET_DISK_PARAMS ENDP

;----------------------------------------------------------------------------;
; Perform 8 bit Checksum on a ROM at DS:0000
;----------------------------------------------------------------------------;
; Input:
;	DS = segment for ROM
;	AL = ROM size in 512k blocks
; Output:
;	ZF if checksum is valid
;
; AX clobbered
;----------------------------------------------------------------------------;
ROM_CHECKSUM PROC
		ASSUME DS:_BIOS
	PUSH	BX
	PUSH	CX
	PUSH	SI
	XOR	SI, SI			; start at offset 0
	CBW					; AH = 0
	XCHG	AL, AH			; convert 512k block count to 16 bit words
	XCHG	AX, CX			; CX = size in 2 byte WORDs
	XOR	BX, BX			; BL = accumulator for sum
CHECKSUM_LOOP:
	LODSW					; next two bytes into AL and AH
	ADD	BL, AL
	ADD	BL, AH			; ZF if sum is 0
	LOOP	CHECKSUM_LOOP		; loop through entire ROM
	POP	SI
	POP	CX
	POP	BX
	RET
ROM_CHECKSUM ENDP

;
; 2 BYTES HERE
;
BYTES_HERE	INT_16

;----------------------------------------------------------------------------;
; INT 16 - Keyboard BIOS Services
;----------------------------------------------------------------------------;
;	INT 16,0   Wait for keystroke and read
;	INT 16,1   Get keystroke status
;	INT 16,2   Get shift status
;----------------------------------------------------------------------------;
		ORG 0E82EH
INT_16 PROC
		ASSUME DS:_BDA
	STI
	PUSH	DS
	PUSH	SI
	MOV	SI, SEG _BDA
	MOV	DS, SI 			; DS = BDA segment
	CMP	AH, 2
	JZ	KB_SHIFT_STATUS 		; AH = 2 - Get Shift Status
	JA	INT_16_DONE			; AH > 2 - not valid, exit
	TEST	AH, AH
	JZ	KB_WAIT_READ		; AH = 0 - Wait for keystroke and read
						; AH = 1 - Get Keystroke (fall through)

;----------------------------------------------------------------------------;
; AH = 1 - Get keystroke status
;----------------------------------------------------------------------------;
; Check if a key press is in buffer and return. Does not wait or remove.
; Output:
;	ZF = 0 if a key pressed (even Ctrl-Break)
;	AX = 0 if no scan code is available
;	AH = scan code
;	AL = ASCII character or zero if special function key
;----------------------------------------------------------------------------;
; Note: many PC references refer to the "read" pointer as "head" and "write"
; pointer as "tail". This seems backwards to me and their typical definition
; in a circular buffer. For the purposes of being consistent with the PC
; termonology, "head" and "tail" are defined as:
;	KB_BUF_HD (1Ah) = (head) next character stored in keyboard buffer
;	KB_BUF_TL (1Ch) = (tail) next spot available in keyboard buffer
;----------------------------------------------------------------------------;
KB_KEY_STATUS PROC
	MOV	SI, OFFSET KB_BUF_HD 	; SI = head ptr
	CLI 					; disable interrupts
	LODSW 				; AX = head, SI = tail ptr
	CMP	AX, WORD PTR[SI] 		; head == tail?
	JNE	KB_BUF_HAS_KEY 		; if not, buffer has a key
KB_KEY_STATUS_DONE:
	STI					; re-enable interrupts
	POP	SI
	POP	DS
	RETF	2 				; IRET with current flags
KB_BUF_HAS_KEY:
	XCHG	AX, SI 			; SI = head
	LODSW 				; AX = buffer[head], SI = next
	JMP	KB_KEY_STATUS_DONE
KB_KEY_STATUS ENDP

;----------------------------------------------------------------------------;
; AH = 0 - Wait for keystroke and read
;----------------------------------------------------------------------------;
; Wait until keystroke is in buffer. Key press is removed from buffer.
; Output:
;	AH = scan code
;	AL = ASCII code
;----------------------------------------------------------------------------;
KB_WAIT_READ PROC
	STI					; enable interrupts
	MOV	SI, OFFSET KB_BUF_HD 	; SI = head ptr
	CLI 					; disable interrupts again
	LODSW 				; AX = head, SI = tail ptr
	CMP	AX, WORD PTR[SI] 		; head == tail?
	JE	KB_WAIT_READ 		; if so, buffer is empty
	XCHG	AX, SI 			; SI = tail
	LODSW 				; AX = buffer[tail], SI = next
	CMP	SI, OFFSET KB_BUF_END 	; is next >= end of buffer?
	JB	KB_GET_READ 		; if not, get tail value
	MOV	SI, OFFSET KB_BUF 	; otherwise, wrap next to buffer top
KB_GET_READ:
	MOV	KB_BUF_HD, SI 		; head ptr = next
INT_16_DONE:
	STI					; enable interrupts (necessary?)
	POP	SI
	POP	DS
	IRET
KB_WAIT_READ ENDP

;----------------------------------------------------------------------------;
; AH = 2 - Get shift status
;----------------------------------------------------------------------------;
; Read Keyboard Flags
; Output:
;	AL = BIOS keyboard flags (from BDA 0040:0017)
;----------------------------------------------------------------------------;
KB_SHIFT_STATUS PROC
	MOV	AL, KB_FLAGS1
	JMP	SHORT INT_16_DONE
KB_SHIFT_STATUS ENDP

INT_16 ENDP

;----------------------------------------------------------------------------;
; Test Memory Address Lines on a 16KB block
;----------------------------------------------------------------------------;
; Write a byte to the first address in a segment and write a different
; value with one address line toggled. Read back the values to ensure
; they are both correct. Repeat 8 times for each starting bit.
;
; Input:
;	ES = segment to test
; Output:
;	ZF if okay, NZ if fail
;	BX = offset of failed byte/line, DI
;
; Clobbers AL
;
; Inspired by:
; http://www.ganssle.com/testingram.htm
; http://www.paul.de/tips/ramtest.htm
; https://www.memtest86.com/tech_memtest-algoritm.html
;----------------------------------------------------------------------------;
MEM_ADDR_TEST PROC
	MOV	AL, 1					; pattern to rotate
	XOR	BX, BX				; base address
	MOV	DI, 02000H				; highest address in 16KB segment
MEM_ADDR_LOOP:
	MOV	ES:[BX], AL				; write to base address
	NOT	AL					; invert value
	MOV	ES:[DI], AL				; write inverted value
	NOT	AL					; revert value
	CMP	ES:[BX], AL				; is base value the same?
	JNZ	MEM_ADDR_ERR			; jump if not
	NOT	AL					; invert value again
	CMP	ES:[DI], AL				; is second value the same?
	JNZ	MEM_ADDR_ERR			; jump if not
	NOT	AL					; revert value again
	ROL	AL, 1					; walk test value
	SHR	DI, 1					; move to next address line
	JNZ	MEM_ADDR_LOOP			; loop until offset is 0
MEM_ADDR_ERR:
	RET
MEM_ADDR_TEST ENDP

;----------------------------------------------------------------------------;
; Test a 16KB block of Memory at ES:0000
;----------------------------------------------------------------------------;
; Trivial read/write test - Write pattern RAM_TEST and reads it back, then 
; repeat with inverse RAM_TEST. If NMI is on, this could trigger a parity
; error.
;
; Input:
; 	ES = segment to test
;
; Clobbers AX, CX, DI
;
; ZF and AX = 0 if okay, NZ if fail
;----------------------------------------------------------------------------;
MEM_TEST PROC
	MOV	AX, RAM_TEST			; test pattern
	CALL	MEM_CHECK
	NOT	AX					; invert pattern

;----------------------------------------------------------------------------;
; Write and verify a 16KB block of Memory at ES:0000
;----------------------------------------------------------------------------;
; Input:
;	AX = pattern to write
; 	ES = segment for test
;
; ZF and AX = 0 if okay, NZ if fail
;----------------------------------------------------------------------------;	
MEM_CHECK:
	MOV	CX, 02000H 				; loop 2000H WORDs
	XOR	DI, DI 				; start at offset 0
	REP	STOSW 				; write test pattern
MEM_TEST_VERIFY:
	MOV	CH, 20H 				; restart loop 2000H
	XOR	DI, DI 				; start at offset 0
	REPZ	SCASW 				; loop until CX = 0 OR WORD is not AX
	XCHG	AX, CX				; AX = 0 if success
	RET
MEM_TEST ENDP

;----------------------------------------------------------------------------;
; Show Memory Test
;----------------------------------------------------------------------------;
; Input:
; 	BX = memory to display (in KB)
; Output:
; 	Console: "Memory: xxxKB" count up POST message
;
; Clobbers: CX, SI
;----------------------------------------------------------------------------;
SHOW_MEM_TEST PROC
	PUSH	BX					; preserve BX

;----------------------------------------------------------------------------;
; Display POST column 1 label "Memory" color option 1
;
	POST_COL_1	POST_MEMORY, POST_CLR_VAL1, 1

	MOV	CL, 3					; zero pad 3 digits
	MOV	AX, BX				; AX = memory in KB
	CALL	OUT_DECU_R				; display as decimal
	PRINT_SZ POST_KB_OK			; display 'KB OK'

	POST_COL_END				; end post column

	POP	BX
	RET

SHOW_MEM_TEST ENDP

;----------------------------------------------------------------------------;
; Write Unsigned word as decimal to console right padded with 0
;----------------------------------------------------------------------------;
; Write an unsigned value in AX out to console, right justified to CX length.
;
; Input: AX value, CX max/justified length
; Output: string at ES:[DI]
;
; TODO: can be further combined with OUT_DECU?
;----------------------------------------------------------------------------;
OUT_DECU_R PROC
	PUSH	AX
	PUSH	BX
	PUSH	DX
	MOV	BX, 10 			; decimal divisor = 10, video page(BH) = 0
	PUSH	BX				; store as terminating value
OUT_DECU_R_DIV:
	XOR	DX, DX 			; clear high word of dividend
	DIV	BX 				; AX = AX / 10, DX = AX % 10
	XCHG	AX, DX 			; AL = remainder
	OR	AL, '0' 			; ASCII convert
	PUSH	AX 				; save to stack
	XCHG	AX, DX 			; AX = remainder
	LOOP	OUT_DECU_R_DIV		; loop while CX > 0
	JMP	SHORT OUT_DECU_LOOP	; the rest is the same as OUT_DECU

;----------------------------------------------------------------------------;
; Write Unsigned word as decimal to console
;----------------------------------------------------------------------------;
; Input: AX value
;----------------------------------------------------------------------------;
OUT_DECU PROC
	PUSH	AX
	PUSH	BX
	PUSH	DX
	MOV	BX, 10 			; decimal divisor = 10, video page(BH) = 0
	PUSH	BX				; store as terminating value
OUT_DECU_DIV:
	XOR	DX, DX 			; clear high word of dividend
	DIV	BX 				; AX = AX / 10, DX = AX % 10
	XCHG	AX, DX 			; AL = remainder
	OR	AL, '0' 			; ASCII convert
	PUSH	AX 				; save to stack
	XCHG	AX, DX 			; AX = remainder
	TEST	AX, AX 			; is remainder zero?
	JNZ	OUT_DECU_DIV		; loop while CX > 0
OUT_DECU_LOOP:
	POP	AX				; AL = next ASCII digit
	CMP	AL, BL			; AL = 10? If so, end
	JZ	OUT_DECU_DONE
	MOV	AH, 0EH			; Write AL to screen TTY mode
	INT	10H
	JMP	SHORT OUT_DECU_LOOP
OUT_DECU_DONE:
	POP	DX
	POP	BX
	POP	AX
	RET
OUT_DECU ENDP
OUT_DECU_R ENDP

;----------------------------------------------------------------------------;
; INT 9 - Test keyboard during POST
;----------------------------------------------------------------------------;
INT_09_POST PROC
	PUSH	AX
	POST_FLAG_CLR PKI				; clear POST test int flag
	IN	AL, PPI_A				; read keyboard scan from PPI
	CMP	AL, 0AAH
	JNZ	INT_09_POST_DONE
	POST_FLAG_SET PKI				; POST keyboard test flag
INT_09_POST_DONE:
	IN	AL, PPI_B				; read keyboard status
	OR	AL, MASK PBKB OR MASK PBKC	; set clear keyboard and enable clock
	OUT	PPI_B, AL				; write to PPI Control Port B
	MOV	AL, INT_EOI				; Send End of Interrupt
	OUT	INT_P0, AL
	POP	AX
	IRET
INT_09_POST ENDP

;----------------------------------------------------------------------------;
; Locate cursor to column on current line
;----------------------------------------------------------------------------;
; Input:
; - AL = new col
;
; Size: 23 bytes
;----------------------------------------------------------------------------;
MOVE_COL PROC
	PUSH	AX				; must preserve all of these
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	AX				; preserve AL on INT 10H call
	XOR	BH, BH 			; video page 0
	MOV	AH, 3 			; get cursor position
	INT	10H 				; DH = row, DL = column
	POP	AX
MOVE_COL_SET:
	MOV	DL, AL			; set new column
	MOV	AH, 2 			; set cursor position
	INT	10H 				; row = DH, column = DL
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
MOVE_COL ENDP

;----------------------------------------------------------------------------;
; Additional INT 9h - Keyboard Code
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; KB Ctrl-NumLock Screen Pause
;----------------------------------------------------------------------------;
INT_KB_SET_PAUSE PROC
			ASSUME DS:_BDA
	MOV	AL, INT_EOI 			; End of Interrupt OCW
	OUT	INT_P0, AL				; write EOI to port 0
	MOV	BX, OFFSET KB_FLAGS2		; (-1 byte to use indirect addr)
	OR	BYTE PTR [BX], MASK K2PA	; set PAUSE flag

				IF CGA_SNOW_REMOVE GT 0
;----------------------------------------------------------------------------;
; Make sure CGA is not currently being blanked
;
	CALL	INT_10_IS_CGA80			; ZF = 1 if CGA 80 col
	JNZ	INT_KB_PAUSE_LOOP			; jump if not CGA 80 col
	MOV	AL, VID_MODE_REG			; get default CGA control register
	MOV	DX, CGA_CTRL			; DX = CGA control port 03D8h
	OUT	DX, AL				; enable video signal
				ENDIF

;----------------------------------------------------------------------------;
; Loop until Pause flag is cleared
;
INT_KB_PAUSE_LOOP:
	HLT						; be a good neighbor
	NOP						; let another interrupt happen
	TEST	BYTE PTR [BX], MASK K2PA	; check the Pause flag
	JNZ	INT_KB_PAUSE_LOOP			; loop until clear
	JMP	INT_KB_DONE				; exit INT
INT_KB_SET_PAUSE ENDP

;----------------------------------------------------------------------------;
; INT 9 - Keyboard Additional Data Tables
;----------------------------------------------------------------------------;
; When CTRL held, modify ASCII codes for these scan codes (10 bytes)
;
INT_KB_CTRL_ASC_TBL LABEL BYTE
	DB	00H, 03H				; Ctrl 2	-> ASCII 0
	DB	1EH, 07H				; Ctrl 6	-> ASCII 1EH
	DB	1FH, 0CH				; Ctrl '-'	-> ASCII 1FH
	DB	7FH, 0EH				; Ctrl BS 	-> ASCII 07FH
	DB	0AH, 1CH				; Ctrl Enter -> ASCII 0AH

;----------------------------------------------------------------------------;
; When CTRL held, modify scan codes for these scan codes (14 bytes)
;
INT_KB_CTRL_SCAN_TBL LABEL BYTE
	DB	77H, 47H 				; Ctrl Home
	DB	84H, 49H 				; Ctrl PgUp
	DB	73H, 4BH 				; Ctrl Left Arrow
	DB	74H, 4DH 				; Ctrl Right Arrow
	DB	75H, 4FH 				; Ctrl End
	DB	76H, 51H 				; Ctrl PgDn
	DB	72H, 37H				; Keypad * / PrtSc

L_INT_KB_CTRL_ASC_TBL	EQU ($-INT_KB_CTRL_ASC_TBL)/2		; 12 total
L_INT_KB_CTRL_SCAN_TBL	EQU ($-INT_KB_CTRL_SCAN_TBL)/2-1	; 6

;----------------------------------------------------------------------------;
; Clear keyboard circular buffer
;----------------------------------------------------------------------------;
; Clear/init circular buffer at KB_BUF
; Clobbers AX
;
; Size: 13h
;----------------------------------------------------------------------------;
KB_BUF_CLEAR PROC
		ASSUME ES:_BDA
	PUSH	ES 					; save ES
	PUSH	DI
	MOV	AX, SEG _BDA 			; get BDA segment
	MOV	ES, AX
	MOV	AX, WORD PTR ES:[KB_BUF_ST] 	; AX = original start of buffer
	MOV	DI, OFFSET ES:KB_BUF_HD 	; DI = buffer head
	STOSW 					; write to head pointer
	STOSW 					; write to tail pointer
	POP	DI
	POP	ES
	RET
KB_BUF_CLEAR ENDP

;
; 2 bytes here
;
BYTES_HERE	INT_09

;----------------------------------------------------------------------------;
; INT 9 - Keyboard Interrupt IRQ1 (Hardware Handler)
;----------------------------------------------------------------------------;
; Handles hardware Interrupt generated by the KBC connected to IRQ 1. The 
; scan code that is received is translated to all of the behaviors and key
; combinations used by the PC.
;
;----------------------------------------------------------------------------;
; References:
;  https://stanislavs.org/helppc/scan_codes.html
;  https://stanislavs.org/helppc/make_codes.html
;  https://stanislavs.org/helppc/keyboard_commands.html
;  https://stanislavs.org/helppc/8042.html
;  http://www.techhelpmanual.com/106-int_09h__keyboard_interrupt.html
;  https://www.phatcode.net/res/223/files/html/Chapter_20/CH20-1.html
;
; KBFLAGS1 RECORD	K1IN:1,K1CL:1,K1NL:1,K1SL:1,K1AL:1,K1CT:1,K1LS:1,K1RS:1
; KBFLAGS2 RECORD	K2IN:1,K2CL:1,K2NL:1,K2SL:1,K2PA:1,K2SY:1,K2LA:1,K2LC:1
;----------------------------------------------------------------------------;
; Things you must do:
; - Check for a scan code from the KBC via PPI Port A (60h)
; - Clear and Enable the keyboard bit (7) on PPI Port B
; - Examine the Make or Break system scan code
; - If a toggle key (Shift, Alt, Ctrl, Caps Lock, Num Lock or Scroll Lock),
;	update that flag in the BDA (17-18h)
; - Determine if the scan code is altered by an active shift or toggle state
; - If Ctrl-Alt-Del is pressed, do a warm reboot of the system
; - If Print Screen is pressed, call INT 05h
; - If Pause/Ctrl-NumLock is pressed, enter pause/hold state
; - If Ctrl-Break is pressed, call INT 1Bh
; - Handle any special, non-standard translations
; - Translate printable chars to their ASCII/CP-437 value
;
; In short, it needs to do this:
;    https://stanislavs.org/helppc/scan_codes.html
;
; TODO: this still needs some clean up.
;----------------------------------------------------------------------------;
		ORG 0E987H
INT_09 PROC
			ASSUME DS:_BDA
	PUSH	AX						; save AX first
	IN	AL, PPI_A 					; read scan code from PPI Port A
	MOV	AH, AL					; save scan code to AH
	IN	AL, PPI_B 					; read Control Port B
	PUSH	AX						; save status, and I/O delay
	OR	AL, MASK PBKB				; set clear keyboard bit
	OUT	PPI_B, AL 					; write to Control Port B
	POP	AX						; restore status, and I/O delay
	OUT	PPI_B, AL 					; write to Control Port B

;----------------------------------------------------------------------------;
; Send non-specific EOI to PIC
;
	MOV	AL, INT_EOI 				; End of Interrupt OCW
	OUT	INT_P0, AL					; write EOI to port 0
	STI							; enable interrupts
	CLD							; string functions increment
	PUSH	BX						; save other used registers
	PUSH	CX						; (now that interrupts are on)
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	DS
	PUSH	ES
	MOV	AL, AH					; AL = original scan code
	CMP	AL, 0FFH 					; check for Detection Error/Overrun
	JZ	INT_KB_MEEP_DONE				; If overrun, meep and exit
	MOV	DX, SEG _BDA 				; DS = BIOS Data Area
	MOV	DS, DX
	MOV	DX, KB_FLAGS				; DL=KB_FLAGS1, DH=KB_FLAGS2

;----------------------------------------------------------------------------;
; 1. Is a function key?
; Function keys have different scan codes based on shift, ALT or CTRL state
;
KB_INT_CHECK_FN_KEY:
	CMP	AL, 044H					; is above F10 scan code?
	JA	KB_INT_CHECK_FN_KEY_DONE
	CMP	AL, 03BH					; is below F1 scan code?
	JB	KB_INT_CHECK_FN_KEY_DONE
	MOV	AL, 0						; ASCII always 0 on F-keys

;----------------------------------------------------------------------------;
; Is a Function key. Check if shift, ALT or Ctrl is held?
;
	TEST	DL, MASK K1AL OR MASK K1CT OR MASK K1LS OR MASK K1RS
	JZ	KB_INT_CHECK_FN_KEY_DONE

KB_INT_CHECK_FN_ALT:					; is it ALT?
	TEST	DL, MASK K1AL
	JZ	KB_INT_CHECK_FN_SHIFT
	ADD	AH, 2DH
	JMP	SHORT KB_INT_PUT_BUFFER_2

KB_INT_CHECK_FN_SHIFT:					; is it shift?
	TEST	DL, MASK K1LS OR MASK K1RS
	JZ	KB_INT_CHECK_FN_CTRL
	ADD	AH, 19H
	JMP	SHORT KB_INT_PUT_BUFFER_2

KB_INT_CHECK_FN_CTRL:					; must be CTRL
	ADD	AH, 23H

KB_INT_PUT_BUFFER_2:					; fit short jumps above
	JMP	SHORT KB_INT_PUT_BUFFER

KB_INT_CHECK_FN_KEY_DONE:				; not a function key

;----------------------------------------------------------------------------;
; 2. Handle "early" Ctrl such as Ctrl-Break and Ctrl-NumLock
;
	TEST	DL, MASK K1CT				; is Ctrl held?
	JZ	KB_INT_IS_NUM				; if not, skip to IS_NUM

;----------------------------------------------------------------------------;
; Is Ctrl-Break?
;
	CMP	AL, 46H					; Scroll Lock (Break)
	JNZ	INT_KB_CHECK_CTRL_NUM			; jump if not Break

INT_KB_CTRL_BREAK:
	CALL	KB_BUF_CLEAR				; clear keyboard buffer
	MOV	BIOS_BREAK, 10000000b			; BIOS break flag
	INT	1BH						; call BIOS Break Handler
	JMP	SHORT INT_KB_DONE_2

;----------------------------------------------------------------------------;
; Is Ctrl-NumLock (Pause)?
;
INT_KB_CHECK_CTRL_NUM:
	CMP	AL, 45H					; is Num Lock key?
	;CMP	AL, 35H					; key pad / (for testing)
	JNZ	KB_INT_IS_NUM				; if not, continue to num pad
	JMP	INT_KB_SET_PAUSE				; otherwise put in Pause

;----------------------------------------------------------------------------;
; Emit a feeble meep and exit
;
INT_KB_MEEP_DONE:
	CALL	MEEP
INT_KB_DONE_2:
	JMP	SHORT INT_KB_DONE

;----------------------------------------------------------------------------;
; 3. Handle numeric keypad entry according to the following:
;
;	Num	Shift	ASCII
; 	0	0	0
;	0	1	'0'
;	1	0	'0'
;	1	1	0
;
KB_INT_IS_NUM:
	TEST	DL, MASK K1NL				; is NUM LOCK on?
	JZ	KB_INT_IS_NUM_DONE			; if not, do nothing
	CMP	AL, 53H					; is higher than Del key?
	JA	KB_INT_IS_NUM_DONE
	CMP	AL, 47H					; is lower than Home/7 key?
	JB	KB_INT_IS_NUM_DONE

;----------------------------------------------------------------------------;
; Keypad number pressed and Num Lock is on, so invert shift behavior.
;
	SHL	AL, 1						; invert NumLock and Shift
	TEST	DL, MASK K1LS OR MASK K1RS		; behavior and jump ahead
	JZ	KB_INT_UC
	JMP	SHORT KB_INT_SHIFT

KB_INT_IS_NUM_DONE:

;----------------------------------------------------------------------------;
; 4. Do scan code to ASCII translation
;----------------------------------------------------------------------------;
KB_INT_CHAR:						; is a regular key ?
	SHL	AL, 1						; align index for table
	TEST	DL, MASK K1LS OR MASK K1RS OR MASK K1AL	; is either shift key or ALT already pressed?
	JNZ	KB_INT_UC					; if so, use uppercase table
KB_INT_SHIFT:
	INC	AX 						; if not shifted, increment one to use lower case
KB_INT_UC:
	MOV	BX, OFFSET KEY_SCAN_TBL
KB_INT_XLAT:
	XLAT	CS:[BX]					; ASCII key in AL = CS:BX[AL]
	TEST	AL, AL					; a is flag key code?
	;JS	INT_KB_IS_FLAG
	JNS	KB_INT_NOT_FLAG
	JMP	INT_KB_IS_FLAG
KB_INT_NOT_FLAG:
	TEST	AH, AH					; test high bit of scan code
	JS	INT_KB_DONE					; if set, it is an unhandled break code
KB_INT_IS_CAPS:
	TEST	DL, MASK K1CL				; is CAPS LOCK on?
	JZ	KB_INT_IS_CAPS_DONE
	CALL	IS_ALPHA					; CF if AL is not [A-Za-z]
	JC	KB_INT_IS_CAPS_DONE
	XOR	AL, 'a'-'A'					; toggle case
KB_INT_IS_CAPS_DONE:

;----------------------------------------------------------------------------;
; 5. Handle ALT chars that require ASCII translation
;
KB_INT_IS_ALT:
	TEST	DL, MASK K1AL				; is ALT currently held?
	JNZ	INT_KB_ALT

;----------------------------------------------------------------------------;
; 6. Handle additional Non-ALT special case chars
;
	CMP	AX, 3700H					; is Shift-PrtSc?
	JZ	KB_INT_PRTSC				; jump if so
	CMP	AX, 4C00H					; Numeric 5 key (unshifted)
	JZ	INT_KB_DONE					; discard and exit

KB_INT_IS_ALT_DONE:

;----------------------------------------------------------------------------;
; 7. Handle CTRL chars
;
KB_INT_IS_CTRL:
	TEST	DL, MASK K1CT				; is CTRL currently held?
	;JNZ	INT_KB_CTRL
	JZ	KB_INT_IS_CTRL_DONE			; jump if not held
	JMP	INT_KB_CTRL

KB_INT_IS_CTRL_DONE:

;----------------------------------------------------------------------------;
; Test if in Ctrl-NumLock PAUSE
; If in Pause, any remaining key will exit and be discarded
;
KB_INT_IS_PAUSE:
	TEST	DH, MASK K2PA				; is in pause?
	JZ	KB_INT_PUT_BUFFER
	AND	KB_FLAGS2, NOT MASK K2PA		; clear pause flag
	JMP	SHORT INT_KB_DONE				; discard key and exit int

;----------------------------------------------------------------------------;
; All special cases have been handled
; - put AX into keyboard buffer
;
KB_INT_PUT_BUFFER:
	MOV	DI, KB_BUF_TL 				; DI = tail ptr
	LEA	SI, [DI+2]					; SI = next (maybe)
	CMP	SI, OFFSET KB_BUF_END			; is next >= end of buffer?
	JB	KB_INT_CHECK_FULL 			; if not, check if buffer is full
	MOV	SI, OFFSET KB_BUF 			; otherwise, wrap to first address
KB_INT_CHECK_FULL:
	CMP	SI, KB_BUF_HD 				; next == head?
	JZ	INT_KB_MEEP_DONE				; Beep if ZF - buffer is full
	MOV	[DI], AX 					; buffer[head] = AX
	MOV	KB_BUF_TL, SI 				; tail = next

;----------------------------------------------------------------------------;
; Restore registers and exit
;
INT_KB_DONE:
	POP	ES
	POP	DS
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	IRET

;----------------------------------------------------------------------------;
; Handle Shift-PrtSc
;
KB_INT_PRTSC:
	INT	5H						; call break handler
	JMP	SHORT INT_KB_DONE

;----------------------------------------------------------------------------;
; 6. Only ALT key is held (no CTRL)
;
; Space bar is the only key that returns the same scan code and ASCII code 
; when ALT is held.
;
INT_KB_ALT PROC
	CMP	AH, 39H					; is space bar?
	JZ	KB_INT_IS_ALT_DONE			; continue
	MOV	BX, AX
	MOV	AL, 0						; AL will be 0 for any others

CHECK_TOP_ROW_NUM:
	CMP	AH, 0DH					; is above '=' scan code?
	JA	CHECK_ALT_ON
	CMP	AH, 2
	JB	CHECK_ALT_ON
	ADD	AH, 76H
	JMP	SHORT KB_INT_PUT_BUFFER

;----------------------------------------------------------------------------;
; 7. Check for ALT + 000 numeric entry
; Alt held, and number is valid numeric keypad
; Note: AH must be preserved
;
CHECK_ALT_ON:
	SUB	BL, '0'					; ASCII convert and test
	JB	INT_KB_NOT_ALT_000			; is 
	CMP	BL, 9
	JA	INT_KB_NOT_ALT_000

INT_KB_IS_ALT_000:
	MOV	AL, KB_ALT					; get partial working byte
	MOV	BH, 10					; multiply by 10
	MUL	BH						; AL = AL * 10
	ADD	AL, BL					; Add new unit digit
	MOV	KB_ALT, AL					; save to BDA
	MOV	AL, 0						; ASCII code is 0
INT_KB_DONE2:
	JMP	SHORT INT_KB_DONE				; interrupt complete

; Hack for short conditional jump
INT_KB_NOT_ALT_000:

;----------------------------------------------------------------------------;
; 8. Check for ALT modified chars that are skipped
; Uses table INT_KB_ALT_SKIP
;
	MOV	DI, CS
	MOV	ES, DI
	MOV	DI, OFFSET INT_KB_ALT_SKIP
	MOV	CX, 11					; L_INT_KB_ALT_SKIP
	XCHG	AH, AL
	REPNZ SCASB						; is in table?
	XCHG	AH, AL
	JZ	INT_KB_DONE					; if found, skip
	JMP	KB_INT_IS_ALT_DONE			; otherwise continue

ALT_MOD_LEN	EQU $-INT_KB_NOT_ALT_000+L_INT_KB_ALT_SKIP	; 31 bytes

INT_KB_ALT ENDP

;----------------------------------------------------------------------------;
; 9. Only CTRL key is held (no ALT)
;----------------------------------------------------------------------------;
INT_KB_CTRL_NO_ALT PROC

;----------------------------------------------------------------------------;
; Handle CTRL exceptions after ASCII or scan code is modified. These require
; a lookup table since they do not follow a predictable pattern.
;
	XCHG	AX, BX					; BH = scan code, BL = ASCII
	MOV	CX, 12					; length of table (L_INT_KB_CTRL_ASC_TBL)
	MOV	SI, OFFSET INT_KB_CTRL_ASC_TBL
INT_KB_CTRL_ASC_TBL_LOOP:
	LODS	WORD PTR CS:[SI]				; AH = scan code, AL = new ASCII
	CMP	AH, BH					; scan code match?
	LOOPNZ INT_KB_CTRL_ASC_TBL_LOOP		; if not keep looping until end
	JNZ	INT_KB_CTRL_ASC_TBL_DONE		; no matches, restore AX and continue
	CMP	CL, 6						; was first list segment? (L_INT_KB_CTRL_SCAN_TBL)
	JG	INT_KB_CTRL_NO_DONE			; if so, match found and AX is set, exit
	MOV	AH, AL					; replace scan code
	MOV	AL, 0						; ASCII code 0
INT_KB_CTRL_NO_DONE:
	JMP	KB_INT_IS_CTRL_DONE			; AX set, exit
INT_KB_CTRL_ASC_TBL_DONE:
	XCHG	AX, BX					; restore AX

;----------------------------------------------------------------------------;
; Skip ; ' `
;
	CMP	AH, 27H					; pass < 27
	JB	INT_KB_CTRL_ALPHA
	CMP	AH, 29H					; pass > 29
	JA	INT_KB_CTRL_ALPHA
	JMP	INT_KB_DONE					; skip 27-29

;----------------------------------------------------------------------------;
; For scan codes 10H-32H return only low 5 bits of ASCII code when CTRL is held
;
INT_KB_CTRL_ALPHA:
	CMP	AH, 10H
	JB	INT_KB_CTRL_NO_ALT_1
	CMP	AH, 32H
	JA	INT_KB_CTRL_NO_ALT_1
	AND	AL, 00011111B				; adjust ASCII value
	JMP	SHORT INT_KB_CTRL_NO_DONE
INT_KB_CTRL_NO_ALT_1:

;----------------------------------------------------------------------------;
; If scan code between 02H-35H and hasn't been modified yet, return nothing
;
	CMP	AH, 2
	JB	INT_KB_CTRL_NO_DONE			; pass < 2
	CMP	AH, 35H
	JA	INT_KB_CTRL_NO_DONE			; pass > 35
	JMP	INT_KB_DONE					; don't return 2-35?

INT_KB_CTRL_NO_ALT ENDP

;----------------------------------------------------------------------------;
; 8. Ctrl key is held
;----------------------------------------------------------------------------;
INT_KB_CTRL:
	TEST	DL, MASK K1AL				; is ALT also currently held?
	JZ	INT_KB_CTRL_NO_ALT			; jump if no ALT

;----------------------------------------------------------------------------;
; 9. Ctrl-Alt keys are held
;----------------------------------------------------------------------------;
INT_KB_CTRL_ALT PROC
	CMP	AH, 53H					; Del key
	;JZ	INT_KB_CTRL_ALT_DEL			; three finger salute
	JNZ	INT_KB_CTRL_ALT_1				; jump if not Ctrl-Alt-Del

;----------------------------------------------------------------------------;
; Handle Ctrl-Alt-Del - warm reboot
;
INT_KB_CTRL_ALT_DEL:
	CALL	BEEP
	MOV	WARM_FLAG, WARM_BOOT			; set warm boot flag
	JMP	POWER_ON					; warm reboot

INT_KB_CTRL_ALT ENDP

;----------------------------------------------------------------------------;
; 10. Handle Ctrl-Alt, but not Del
;
INT_KB_CTRL_ALT_1:

			IF ARCH_TYPE EQ ARCH_TURBO
;----------------------------------------------------------------------------;
; Is Turbo speed toggle Ctrl-Alt-+ hotkey?
;
	CMP	AH, 4EH					; numeric pad + key
	;JZ	INT_KB_TOGGLE_TURBO
	JNZ	INT_KB_CTRL_ALT_1_DONE			; put in buffer as-is and exit

;	;CMP	AH, 4AH					; numeric pad - key
;	;JZ	INT_KB_TURBO_MINUS

;----------------------------------------------------------------------------;
; Handle Turbo speed mode toggle
;
	CALL	INT_KB_TOGGLE_TURBO			; meep meep and switch speed
	JMP	INT_KB_DONE

			ENDIF

INT_KB_CTRL_ALT_1_DONE:
	JMP	KB_INT_IS_CTRL_DONE			; put in buffer as-is and exit

;----------------------------------------------------------------------------;
; 5. Is a flag key?
;----------------------------------------------------------------------------;;
;  40:18	Keyboard Flags Byte 2 (High)
; 84218421
; 7 	    |			- K2IN	insert key is depressed
;  6 	    |			- K2CL	caps-lock key is depressed
;   5	    |			- K2NL	num-lock key is depressed
;    4    |			- K2SL	scroll lock key is depressed
;     3   |			- K2PA	suspend key has been toggled
;      2  |			- K2SY	system key depressed and held
;       1 |			- K2LA	left ALT key depressed
;        0|			- K2LC	left CTRL key depressed
;
INT_KB_IS_FLAG PROC
	MOV	DI, CS					; ES to BIOS code
	MOV	ES, DI
	MOV	DI, OFFSET KEY_FLAG_ON_TBL
	MOV	AL, AH					; AL = original scan code
	AND	AL, 01111111B				; clear high bit for search
	MOV	CL, 1						; set up bit mask counter
INT_KB_FLAG_LOOP:
	SCASB 						; look for scan code
	JZ	INT_KB_FLAG_FOUND
	SHL	CL, 1 					; CL will contain bit mask
	JNZ	INT_KB_FLAG_LOOP				; CF if not found too
	JMP	KB_INT_NOT_FLAG
INT_KB_FLAG_FOUND:
	CLI
	MOV	AL, CL					; move to AL for work

;----------------------------------------------------------------------------;
; Ins, Caps, Num, Scrl send break codes, but state is kept by BIOS so ignore those.
;
	TEST	AL, MASK K1IN OR MASK K1CL OR MASK K1NL OR MASK K1SL
	JZ	INT_KB_NOT_ICNS				; don't clear on break code on these
	TEST	AH, AH					; is Ins, Caps, Num, Scrl break code?
;	JS	INT_KB_FLAG_DONE				; if so, do nothing and exit
	JNS	INT_KB_ICNS_MAKE				; if not, jump to make

;----------------------------------------------------------------------------;
; Handle KB_FLAGS2 for Ins, Caps, Num, Scroll Lock for both make and break
;
INT_KB_ICNS_BREAK:
	NOT	AL
	AND	KB_FLAGS2, AL				; clear flag in KB_FLAGS2
	JMP	SHORT	INT_KB_FLAG_DONE
INT_KB_ICNS_MAKE:
	OR	KB_FLAGS2, AL				; set flag in KB_FLAGS2

;----------------------------------------------------------------------------;
; Otherwise simply toggle the flag for Ins, Caps, Num, Scrl.
;
; Note: this approach does not seem to work properly for Alt, Ctrl, Shift, 
; Caps Lock. It appears that order is not completely guaranteed so it is
; possible to receive to break codes for the same key in a row, which mean
; just toggling will cause flags to be lost.
;
; Note 2: The Ins key passes through as a key press with code 5200H.
;
INT_KB_FLAG_TOGGLE:
	XOR	KB_FLAGS1, AL				; toggle flag
	TEST	AL, MASK K1IN				; is insert key?
	MOV	AL, 0
	JNZ	INT_KB_PUT_BUFFER_2			; pass through as a key if so
INT_KB_DONE3:
	JMP	INT_KB_DONE

;----------------------------------------------------------------------------;
; Scan code for Alt, Ctrl, Left or Right Shift
; On make code, set flag.  On break code, clear flag.
;
INT_KB_NOT_ICNS:

;----------------------------------------------------------------------------;
; Handle KB_FLAGS2 for Ctrl or Alt
;
	TEST	AL, MASK K1AL OR MASK K1CT		; is Alt or Ctrl?
	JZ	INT_KB_NOT_ICNS_1				; jump if not
	SHR	AL, 1						; adjust for KB_FLAGS2
	SHR	AL, 1
	XOR	KB_FLAGS2, AL				; toggle flag
	MOV	AL, CL					; restore AL

INT_KB_NOT_ICNS_1:
	TEST	AH, AH					; is a break code?
	JNS	INT_KB_FLAG_SET				; if not, set flag

INT_KB_FLAG_CLEAR:
	NOT	AL						; invert mask
	AND	KB_FLAGS1, AL				; clear flag
	CMP	CL, MASK K1AL				; was it ALT key?
	JZ	INT_KB_ALT_BREAK				; if so, handle more ALT break
	;JMP	INT_KB_DONE					; INT_KB_DONE short jump too far
	JMP	SHORT INT_KB_FLAG_DONE			; (saves 1 byte)

INT_KB_FLAG_SET:
	OR	KB_FLAGS1, AL				; set flag

INT_KB_FLAG_DONE:
	JMP	INT_KB_DONE					; done

INT_KB_IS_FLAG ENDP

;----------------------------------------------------------------------------;
; ALT has just been released
;----------------------------------------------------------------------------;
; Check if there a partial value of ALT+000 (ALT-GR) numpad entry work byte?
;
INT_KB_ALT_BREAK:
	MOV	AL, KB_ALT
	TEST	AL, AL			; is ALT working sum 0?
	JZ	INT_KB_DONE3		; if so, end
	MOV	AH, 0				; Scan code is 0
	MOV	KB_ALT, AH			; clear ALT byte working sum
INT_KB_PUT_BUFFER_2:
	JMP	KB_INT_PUT_BUFFER		; use this value as output char

;----------------------------------------------------------------------------;
; Keyboard scancode mapping tables
;----------------------------------------------------------------------------;
; For each scan code this table contains ASCII characters. The first byte is
; the shifted (shift held) ASCII char, followed by the non-shifted ASCII char.
;
; Flag chars (noted by *) return their scan code with most sig bit set 
; (also their break code).
;----------------------------------------------------------------------------;
KEY_SCAN_TBL:
	DB	2 DUP(0), 2 DUP(1BH) 		; 00-01H	None, Escape
	DB	'!1@2#3$4%5^6' 			; 02-		(Top row keys)
	DB	'&7*8(9)0_-+='			;   -0DH
	DB	8, 8, 0, 9 				; 0E-0FH	Backspace, Tab
	DB	'QqWwEeRrTtYy' 			; 10-		(Second row keys)
	DB	'UuIiOoPp{[}]' 			;    1BH
	DB	2 DUP(0DH) 				; 1C		Enter
	DB	2 DUP(01DH OR 80H) 		; 1D		*Ctrl
	DB	'AaSsDdFfGgHh'			; 1E-		(Third row keys)
	DB	'JjKkLl:;"', "'", '~`'		;   -29H
	DB	2 DUP(02AH OR 80H)  		; 2A		*Left shift
	DB	'|\ZzXxCcVvBb' 			; 2B-		(Fourth row keys)
	DB	'NnMm<,>.?/' 			;   -35H
	DB	2 DUP(36H OR 80H)			; 36H		*Right Shift
	DB	0, '*' 				; 37H		PrtSc/'*'
	DB	2 DUP(38H OR 80H)			; 38H		*Alt
	DB	2 DUP(' ')				; 39H		Space
	DB	2 DUP(3AH OR 80H) 		; 3AH		*Caps Lock

;----------------------------------------------------------------------------;
; IMPORTANT NOTE: these next two tables are placed here to fill the "hole"
; for the F1-F10 keys, so MUST be exactly 20 bytes to maintain the table
; index. Left in commented out below for reference:

;	DW	10 DUP(0) 				; 3B-44H	F1-F10

;----------------------------------------------------------------------------;
; Table for scan codes that are keys that set flags.
; The byte's index corresponds to the flag bit position in BDA's KB_FLAGS1.
; Length: 8 bytes
;
KEY_FLAG_ON_TBL:			;                            ICNSATLR
	DB	36H			; Right shift on	0110110 -> 00000001
	DB	2AH			; Left shift on	0101010 -> 00000010
	DB	1DH			; cTrl on		0011101 -> 00000100
	DB	38H			; Alt on		0111000 -> 00001000
	DB	46H			; Scroll lock on 	1000110 -> 00010000
	DB	45H			; Num lock on	1000101 -> 00100000
	DB	3AH			; Caps lock on	0111010 -> 01000000
	DB	52H			; Insert on		1010010 -> 10000000
L_KEY_FLAG_ON_TBL	EQU $-KEY_FLAG_ON_TBL

;----------------------------------------------------------------------------;
; Alt keys that are "skipped" and return no scan codes
; Length: 10 bytes
;
INT_KB_ALT_SKIP	LABEL	BYTE
	DB	0FH					; Tab
	DB	1CH					; Enter
	DB	27H					; ;
	DB	28H					; '
	DB	29H					; `
	DB	2BH					; \
	DB	33H					; ,
	DB	34H					; .
	DB	35H					; /
	DB	37H					; * PrcSc
L_INT_KB_ALT_SKIP	EQU $-INT_KB_ALT_SKIP

	DB	2 DUP(0)				; pad 2 bytes to maintain index

; must be KEY_FLAG_ON_TBL + 20 here to maintain index

KEY_SCAN_TBL_HIGH:
	DB	2 DUP(45H OR 80H)			; 45H		*Num Lock
	DB	2 DUP(46H OR 80H)			; 46H		*Scroll Lock
	DB	'7', 0				; 47H		Home/7
	DB	'8', 0				; 48H		Up/8
	DB	'9', 0				; 49H		PgUp/9
	DB	2 DUP('-')				; 4AH		Keypad '-'
	DB	'4', 0				; 4BH		Left/4
	DB	'5', 0				; 4CH		Center/5
	DB	'6', 0				; 4DH		Right/6
	DB	2 DUP('+')				; 4EH		Keypad '+'
	DB	'1', 0				; 4FH		End/1
	DB	'2', 0				; 50H		Down/2
	DB	'3', 0				; 51H		PgDn/3
	DB	'0', 52H OR 80H			; 52H		*Ins/0
	DB	'.', 0				; 53H		Del
	DB	2 DUP(0)				; 54H		SysReq
L_KEY_SCAN_TBL EQU $-KEY_SCAN_TBL

INT_09 ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	INT_13

;----------------------------------------------------------------------------;
; INT 13H - Diskette BIOS Services
;----------------------------------------------------------------------------;
;	INT 13,0  Reset disk system
;	INT 13,1  Get disk status
;	INT 13,2  Read disk sectors
;	INT 13,3  Write disk sectors
;	INT 13,4  Verify disk sectors
;	INT 13,5  Format disk track
;
;  Typical params:
;	AH = function request number
;	AL = number of sectors	(1-128)
;	CH = cylinder number	(0-1023)
;	CL = sector number	(1-17)
;	DH = head number		(0-15)
;	DL = drive number		(0=A:, 1=B:, 80H=C:, 81H=D:) (for AH=2-5)
;	ES:BX = address of user buffer
;
;  Return:
;	CF = 0 if successful
;	   = 1 if error
;	AH = status of operation (https://stanislavs.org/helppc/int_13-1.html)
;
;----------------------------------------------------------------------------;
;  All functions:
;	- return FD_LAST_OP ([41H]) in AH
;	- set CF if error
;	- reset motor shutoff counter
;
;  Reference:
;	https://stanislavs.org/helppc/int_13.html
;	https://stanislavs.org/helppc/765.html
;	NEC Microcomputers, Inc. PD765C Application Note 8 (Mar 1979)
;
;  Ports:
;	3F0-3F7 Floppy disk controller (except PCjr)
;	3F0 Diskette controller status A
;	3F1 Diskette controller status B
;	3F2 controller control port
;	3F4 controller status register
;	3F5 data register (write 1-9 byte command, see INT 13)
;	3F6 Diskette controller data
;	3F7 Diskette digital input
;
;----------------------------------------------------------------------------;
		ORG 0EC59H
INT_13 PROC
	STI 						; enable interrupts
	CLD
	PUSH	DS
	PUSH	DX
	PUSH	CX	
	PUSH	BX
	PUSH	AX					; save original AX
	PUSH	BX
	MOV	BX, SEG _BDA			; set DS = BDA
	MOV	DS, BX
	POP	BX
	CMP	AH, 1 				; AH = 1?
	JB	INT_13_0 				; AH = 0, jump to Reset
	JZ	INT_13_1 				; AH = 1, jump to Status
	CMP	DL, 3 				; is drive number > 3?
	JA	INT_13_BAD_CMD 			; if so, exit
	CMP	AH, 6 				; AH = 2 through 5?
	JB	INT_13_2_5 				; jump to FDC RWVF command
INT_13_BAD_CMD:
	MOV	FD_LAST_OP, FDC_ST_BADCMD	; otherwise return "bad command"
INT_13_DONE:
	MOV	AL, 2 				; INT_1E[2] = motor shutoff counter
	CALL	INT_1E_PARAM 			; AL = shutoff counter value (37)
	MOV	FD_MOTOR_CT, AL 			; update in BDA
	POP	AX 					; restore original AL
	MOV	AH, FD_LAST_OP 			; AH = last operation status
	POP	BX 					; restore original registers
	POP	CX
	POP	DX
	POP	DS
	CMP	AH, FDC_ST_OK+1			; check AH for error (CF = AH < 1)
	CMC   					; invert CF for return (CF = ! CF)
	RETF	2 					; return from int with current flags

;----------------------------------------------------------------------------;
; INT 13, 0: Reset disk system
;----------------------------------------------------------------------------;
; Performs hard reset on FDC controller
;
; Input:
;	AH = 00
;	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
;		(unused - drive is determined by BDA motor status)
;
; Output:
;	AH = disk operation status  (see INT 13,STATUS)
;	CF = 0 if successful
;	   = 1 if error
;
; To Convert FD_MOTOR_ST to FDC byte use the following table/formula:
;	Motors On 	Drive #
;	0 0 0 0	 	0 			AND with 1111, jump if AL = 0
;	1 x x x		3			TEST bit 1000, if non-zero then AL = 3
;	0 1 x x		2 			Shift right once and AL will be correct
;	0 0 1 x		1 			"
;	0 0 0 x	 	0			"
;
;----------------------------------------------------------------------------;
; Things you must do:
;
;	- if a motor flag is on in BDA, turn it on in the FDC also
;	- clear reset flag in controller and pull heads to track 0
;	- set ALL disks need recalibration on next seek (Why all drives?)
;	- setting the controller reset flag causes the disk to recalibrate
;	  	on the next disk operation
;	- if bit 7 is set, the diskette drive indicated by the lower 7 bits
;		will reset then the hard disk will follow; return code in AH is
;		for the drive requested (this is done by HD BIOS)
;----------------------------------------------------------------------------;
INT_13_0 PROC
	MOV	DX, FDC_CTRL			; port 3F2H, FDC Digital Output
	CLI 						; disable interrupts
	MOV	AL, FD_MOTOR_ST 			; 3FH - Diskette motor status
	MOV	CH, AL 				; save to CH
	AND	AL, 1111B 				; isolate motor status flags
	JZ	INT_13_0_2				; jump if no motors are on, default to 0

;----------------------------------------------------------------------------;
; One motor is on (according to BDA). Convert motor run flags to binary number
; since FDC requires a drive index for the reset.
;
	SHR	AL, 1					; disregard low bit (will be 0 either way)
	TEST	AL, 0100B 				; test for drive 3?
	JZ	INT_13_0_1				; if not drive 3, AL is now correct
	MOV	AL, 3 				; otherwise set AL to drive 3
INT_13_0_1:
			IF CPU_TYPE	EQ CPU_V20
	SHL	CH, 4					; move original low nibble into CH
			ELSE
	MOV	CL, 4 				; move original low nibble
	SHL	CH, CL				;  into high nibble of CH
			ENDIF
	OR	AL, CH 				; combine nibbles with AL

;----------------------------------------------------------------------------;
; Reset the controller by holding FDC reset (bit 2) at 0.
; Flag all drives for recalibration (not just the drive in DL)
; Clear last FDC operation status in BDA
;
INT_13_0_2:
	OR	AL, 1000B 				; enable DMA & I/O interface, FDC reset
	OUT	DX, AL				; send to FDC
	XOR	CX, CX 				; clear CX, delay for FDC to settle	(3)
	MOV	FD_CAL_ST, CL 			; flag all drives for recalibration	(19)
	MOV	FD_LAST_OP, CL 			; clear last operation flags		(19)
	;IO_DELAY_SHORT 				; additional 15 clock cycle delay 	(15)

;----------------------------------------------------------------------------;
; Re-enable FDC by setting bit 2 to 1.
; Wait for Interrupt (WIF) from FDC
;
	OR	AL, 0100B 				; set FDC enable 				(4)
	OUT	DX, AL				; send to FDC
	STI 						; enable interrupts
	CALL	FDC_WAIT_SENSE			; wait for FDC to signal interrupt
	JC	INT_13_0_RESET_BAD
	CMP	AL, 11000000B			; was successful reset?
	JZ	INT_13_0_RESET_DONE		; jump if success, AH = 0
INT_13_0_RESET_BAD:
	MOV	AH, FDC_ST_ERR_FDC		; otherwise, controller failure
INT_13_0_RESET_DONE:
	MOV	FD_LAST_OP, AH			; set last result

;----------------------------------------------------------------------------;
; (Re)send Specify bytes to FDC
;
	MOV	AL, FDC_CMD_SPEC 			; [0] FDC Specify command
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	INT_13_DONE
	MOV	AL, 0					; [1] step rate time, head unload time
	CALL	FDC_SEND_PARAM
	JC	INT_13_DONE
	MOV	AL, 1					; [2] head load time (01H), DMA mode
	CALL	FDC_SEND_PARAM
INT_13_0_DONE:
	JMP	SHORT INT_13_DONE
INT_13_0 ENDP

;----------------------------------------------------------------------------;
; INT 13, 1: Get disk status
;----------------------------------------------------------------------------;
; Output: AL = status of last operation
;----------------------------------------------------------------------------;
INT_13_1 PROC
	POP	AX 					; restore original registers
	MOV	AL, FD_LAST_OP 			; AL = last operation status
	POP	BX
	POP	CX
	POP	DX
	POP	DS
	IRET
INT_13_1 ENDP

;----------------------------------------------------------------------------;
; INT 13, AH=2-5: FDC read/write operations
;----------------------------------------------------------------------------;
; All commands:
;
; 	AL = number of sectors to read  (1-128 dec.)
;	AH = function number
;	CH = track/cylinder number  (0-1023 dec., see below)
;	CL = sector number  (1-17 dec.)
;	DH = head number  (0-15 dec.)
;	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
;	ES:BX = pointer to buffer
;----------------------------------------------------------------------------;
; Things you must do:
;
;	1. Set FD_MOTOR_ST read/write flag for operation
;	2. Motor ON (update BDA)
;		- is motor already on? Skip wait for spin up
;		- wait only for writes?
;		- check if recalibration is necessary
;	3. Set up DMA
;	4. seek drive DL to cylinder CH, head DH
; 	5. send command
;	6. wait for interrupt
;	7. fetch results
;	8. Check FDC status bytes for result
;
; Things you should do:
;	- Check if drive is valid? Check if exists in BDA and not a hard drive
;----------------------------------------------------------------------------;
INT_13_2_5 PROC
	AND	FD_LAST_OP, 0 			; clear last operation
	CALL	FDC_SEEK 				; Turn on motor, CH = track, DL = drive
	JC	INT_13_DONE				; exit if seek error
	PUSH	AX
	PUSH	DX
	XCHG	AX, DX 				; DL = sectors count
	MOV	AL, DH				; AL = function number
	MOV	DH, 01001010B 			; set DMA 8237A write/format mode (AH = 3,5)
	OR	FD_MOTOR_ST, MASK FWRT		; turn on write flag default
	TEST	AL, 1B 				; is write or format mode?
	JNZ	INT_13_2_5_SETUP_DMA		; proceed to setup
	AND	FD_MOTOR_ST, NOT MASK FWRT	; otherwise read or verify (turn off write flag)
	MOV	DH, 01000010B			; 8237A verify mode (AH = 4)
	CMP	AL, 4 				; is verify?
	JZ	INT_13_2_5_SETUP_DMA		; proceed to setup
	MOV	DH, 01000110B			; otherwise, set 8237A read mode (AH = 2)
INT_13_2_5_SETUP_DMA:
	XCHG	AX, DX				; AL = sectors to read, AH = DMA mode
	CALL	FDC_INIT_DMA 			; set up DMA
	POP	DX 					; restore drive number DL
	POP	AX					; restore function number AH
	JC	INT_13_0_DONE			; jump if DMA error
	MOV	AL, 11000101B			; FDC write command
	CMP	AH, 3 				; is write?
	JE	FDC_RWVF				; jump if write
	MOV	AL, 01001101B			; format command w/MFM
	CMP	AH, 5 				; is format command?
	JE	FDC_RWVF 				; jump if format
	MOV	AL, 11100110B 			; FDC read command

;-------------------------------------------------------------------------
; FDC_RWVF: read, write, format or verify sectors
;-------------------------------------------------------------------------
FDC_RWVF:
	PUSH	AX					; preserve AH function number
	CALL	FDC_SEND 				; [0] send command in AL, CF if error
	POP	AX
	JC	FDC_RWV_ERR
	MOV	AL, DH				; AL = head
	XCHG	AX, DX				; AL = drive, AH = head, DL = head, DH = function
	AND	AX, 103H				;  xxxxx     ; unused
	SHL	AH, 1					;       h    ; head number (bit 3)
	SHL	AH, 1					;        dd  ; drive number (bit 1,2)
	OR	AL, AH 				; [1] head / drive
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	CMP	DH, 5					; is format?
	JE	FDC_FORMAT

;-------------------------------------------------------------------------
; FDC_RWV: read, write or verify sectors
;-------------------------------------------------------------------------
; Input:
; 	AL = number of sectors to read (1-128 dec.)
;	CH = track/cylinder number  (0-1023 dec., see below)
;	CL = sector number  (1-17 dec.)
;	DH = head number  (0-15 dec.)
;	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
;	ES:BX = pointer to buffer
; 	(All registers clobbered)
;
; Output:
;	AL = number of sectors read, written or verified
;-------------------------------------------------------------------------
FDC_RWV PROC
	MOV	AL, CH 				; [2] cylinder number
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, DL 				; [3] head number
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, CL 				; [4] sector number
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, 3					; [5] bytes per sector
	CALL	FDC_SEND_PARAM			; 2 = 512 bytes
	JC	FDC_RWV_ERR 
	MOV	AL, 4					; [6] end of track (last sector in track)
	CALL	FDC_SEND_PARAM
	JC	FDC_RWV_ERR
	MOV	AL, 5					; [7] gap length
	CALL	FDC_SEND_PARAM
	JC	FDC_RWV_ERR
	MOV	AL, 6					; [8] data length (if cmd byte 5==0)
	CALL	FDC_SEND_PARAM
	JC	FDC_RWV_ERR
	CALL	FDC_WAIT_STATUS			; wait for WIF and get status
	JC	FDC_RWV_ERR				; check for timeout error
							; fall through for FDC SEC COUNT

;-------------------------------------------------------------------------
; FDC_SEC_COUNT: get the number of sectors read/verified/written
;-------------------------------------------------------------------------
; Input:
;	CH = start track/cylinder number  (0-1023 dec., see below)
;	CL = start sector number  (1-17 dec.)
;	DH = head number  (0-15 dec.)
;	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
; Ouput:
;	AL = sectors transferred
;
; Note: If the operation finishes at the last head/sector of a track, 
;	FDC will report the head/track/sector position to be the beginning 
;	of the next track.
;-------------------------------------------------------------------------
FDC_SEC_COUNT PROC
	MOV	AL, FDC_LAST_ST[5]		; AL = FDC reported end sector
	MOV	DL, CH				; DH = start head, DL = start track
	CMP	DX, WORD PTR FDC_LAST_ST[3]	; did it end on the same head/track?
	JZ	FDC_SEC_COUNT_SAME		; if not, it rolled to next next/track
	MOV	AL, 4					; get INT 1E sectors per track
	CALL	INT_1E_PARAM			; AL = last sector
	INC	AX					; fix INT 13 1-based sector index
FDC_SEC_COUNT_SAME:
	SUB	AL, CL				; AL = last_sector - starting_sector
FDC_SEC_COUNT ENDP				;   returns AL = sectors read

FDC_RWV ENDP					; fall through for exit

;----------------------------------------------------------------------------;
; Done with all disk operations and return AL
;
INT_13_2_5_DONE:
	POP	CX					; discard original AX from INT_13 PROC
	PUSH	AX					; replace with AL = sectors read
INT_13_2_5_EXIT:
	JMP	INT_13_DONE

FDC_RWV_ERR:
FDC_FORMAT_ERR:
	MOV	AL, 0					; on error: sectors read = 0
	JMP	SHORT INT_13_2_5_DONE

;----------------------------------------------------------------------------;
; INT 13, 5: Format Track
;----------------------------------------------------------------------------;
; Input:
;	AH = 05
;	AL = interleave value (XT only)
;	CX = track/cylinder number (see below for format)
;	DH = head number  (0-15 dec.)
;	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
;	ES:BX = pointer to block of "track address fields" (provided by DOS)
;----------------------------------------------------------------------------;
FDC_FORMAT PROC
	MOV	AL, 3					; [2] bytes per sector
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	MOV	AL, 4					; [3] sectors per track
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	MOV	AL, 7					; [4] gap length
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	MOV	AL, 8					; [5] fill byte
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	CALL	FDC_WAIT_STATUS			; wait for WIF and get status
	JMP	SHORT INT_13_2_5_EXIT		; (-1 byte for short double jump)
FDC_FORMAT ENDP

INT_13_2_5 ENDP

;-------------------------------------------------------------------------
; FDC_SEEK: Seek to track
;-------------------------------------------------------------------------
; Input:
;	CH = track
;	DL = drive
;-------------------------------------------------------------------------
FDC_SEEK PROC
	PUSH	AX
	CALL	FDC_RECAL 				; recalibrate if needed
	JC	FDC_SEEK_RECAL_ERR
	MOV	AL, FDC_CMD_SEEK			; seek command (0FH)
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_SEEK_ERR
	MOV	AL, DL 				; AL = drive number
	CALL	FDC_SEND 				; send command, CF if error
	;JC	FDC_SEEK_ERR			; necessary? (not enough bytes)
	MOV	AL, CH 				; AL = track number
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_SEEK_ERR
	CALL	FDC_WAIT_SENSE			; wait for WIF, sense and get status
	JC	FDC_SEEK_ERR
	XOR 	AL, 01100000b			; select interesting bits
	TEST	AL, 01100000b			; ZF = abnormal term. AND seek complete
	JZ	FDC_SEEK_ERR
	MOV	AX, 9
	CALL	INT_1E_PARAM			; AL = head settle time (ms)
	CALL	IO_DELAY_MS				; delay AX ms
	CLC
FDC_SEEK_DONE:
	POP	AX
	RET
FDC_SEEK_ERR:
	OR	FD_LAST_OP, FDC_ST_ERR_SEEK
FDC_SEEK_RECAL_ERR:
	STC
	JMP	SHORT FDC_SEEK_DONE
FDC_SEEK ENDP

;-------------------------------------------------------------------------
; FDC_MOTOR_ON: Turn on motor
;-------------------------------------------------------------------------
; Input:
; 	DL = drive number
; Clobbers: CX
;-------------------------------------------------------------------------
; Things you must do:
;	- is motor already on? Skip wait for spin up
;	- wait only for writes?
;	- check if recalibration is necessary
;
; Things you should do:
;	- check if drive is valid in BDA?
;-------------------------------------------------------------------------
FDC_MOTOR_ON PROC
	PUSH	AX
	PUSH	DX

;-------------------------------------------------------------------------
; Convert drive number to motor run format
;
	MOV	CL, DL 				; move to CL for shift
	AND	CL, 0011B 				; mask just drive number in CL
	MOV	AX, 110H 				; AH -> RUN_ST, AL -> FDC byte
	SHL	AX, CL 				; shift drive flags
	CLI 						; disable interrupts
	MOV	CH, FD_MOTOR_ST			; get current RUN_ST
	TEST	CH, AH 				; is drive already running?
	JNZ	FDC_DRV_ALREADY_ON		; skip startup if so
	OR	AL, CL 				; combine drive number to FDC byte
	OR	AL, 1100B 				; combine enable flags to FDC byte
	MOV	DX, FDC_CTRL			; turn on motor
	OUT	DX, AL				; port 3F2H, FDC Digital Output
	MOV	AL, CH 				; AL = FD_MOTOR_ST
	AND	AL, 11110000B 			; clear low nibble of FD_MOTOR_ST
	OR	AL, AH				; combine nibbles
	MOV	AH, 0FFH				; restart timer to max for motor spinup
	MOV	WORD PTR FD_MOTOR_ST, AX	; write to motor status and timer
	STI 						; enable interrupts
	TEST	AL, MASK FWRT			; Delay for motor spinup if write operation
	JZ	FDC_DRIVE_STARTED 		; if not, bypass delay

;-------------------------------------------------------------------------
; Delay using timer tick counter
;
	MOV	AL, 10				; AL = INT_1E[10]
	CALL	INT_1E_PARAM 			; AL = motor startup time (in 125ms)
	CALL	IO_WAIT_MS_125			; wait AL * 125ms

FDC_DRV_ALREADY_ON:
	MOV	AL, 2 				; AL = INT_1E[2]
	CALL	INT_1E_PARAM			; AL = reset motor counter
	MOV	FD_MOTOR_CT, AL
	STI
FDC_DRIVE_STARTED:
	POP	DX
	POP	AX
	RET
FDC_MOTOR_ON ENDP

;-------------------------------------------------------------------------
; FDC_INIT_DMA: Configure DMA channel 2 for FDC operation
;-------------------------------------------------------------------------
; Input:
;  AL = sectors to read
;  AH = DMA mode:
;	01000110 (46H) - Read
;	01000010 (42H) - Verify
;	01001010 (4AH) - Write
; 	01 			; Mode: Single mode select
; 	  0  			; Address increment
;	   0 			; Auto-initialization disable
;	    xx		; 00=verify, 01=write, 10=read, 11=unused
;	      10		; Channel 2 select
;  ES:BX = pointer to buffer
;
; Output:
;  CF = 0 success, 1 if error DMA exceeds segment
;-------------------------------------------------------------------------
; Things you must do:
;	- Calculate # of bytes to transfer by multiplying AL (sectors) by
;		sector size in INT 1E Disk Base Table.
;	- Calculate linear memory address from ES:BX and normalize to 
;		Paragraph:Offset (P:FFFFH).
;	- Verify that Offset + Byte Count does not exceed the remaining
;		space in that paragraph. The DMA controller can only select one
;		paragraph bank at a time, so writes will NOT wrap to next para.
;		Exit with DMA Boundary error if segment is exceeded.
;	- Reset the high/low byte flip-flop (send any value to I/O port 0CH)
;	- Set DMA mode for Channel 2 to either Verify, Read or Write/Format
;	- Disable interrupts while programming DMA
;	- Set the DMA Page (memory paragraph) for DMA channel 2 (I/O port 81H)
;	- Set the DMA Byte Counter to size of transfer minus 1 (since 
;		DMA's counter is 0-indexed)
;	- Set the DMA Address register to beginning of DMA buffer from ES:BX
;	- Enable interrupts and unmask DMA Channel 2
;
;-------------------------------------------------------------------------
; References:
;  https://pdf1.alldatasheet.com/datasheet-pdf/view/127822/AMD/8237A.html
;  https://wiki.osdev.org/ISA_DMA#Floppy_Disk_DMA_Initialization
;  https://stackoverflow.com/questions/52396915/how-to-write-assembly-language-to-make-dma-works
;  https://userpages.umbc.edu/~squire/intel_book.pdf
;-------------------------------------------------------------------------
FDC_INIT_DMA PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	OUT	DMA_FF, AL			; DMA clear flip-flop (port 0CH) (any value)
	MOV	DX, ES 			; get and shift ES by one nibble
			IF CPU_TYPE EQ CPU_V20
	ROL	DX, 4				; V20 only
			ELSE
	MOV	CL, 4				; DL = highest and lowest nibble of ES
	ROL	DX, CL			; DH = middle nibbles
			ENDIF
	XCHG	AL, AH			; AL = DMA mode, AH = sectors to read
	OUT	DMA_MODE, AL		; write to DMA mode reg (port 0BH)
	XCHG	AL, AH			; AH = DMA mode, AL = sectors to read
	CBW					; AX = zero extend AL (DMA mode always < 80H)
	XCHG	AX, CX			; CX = sectors to read, AX = scratch
	MOV	AL, 3				; get bytes/sector param (0=128, 1=256, 2=512, 3=1024)
	CALL	INT_1E_PARAM		; AL = shift count (default 2 => 512)
	ADD	AL, 7				; additional shifts: bytes/sector * 128
	XCHG	AX, CX			; CL = bytes per sector shifts + 7, AX = sectors to read
	SHL	AX, CL			; AX = bytes to transfer (AX * 2^CL)
	DEC	AX				; AX = bytes to transfer - 1
	XCHG	AX, CX			; CX = bytes to transfer - 1
	MOV	AL, DL			; AL = highest and lowest nibble of ES
	AND	AL, 0FH			; AL = only low nibble of ES
	AND	DL, 0F0H			; DX = low three nibbles (shifted left 4)
	ADD	DX, BX			; DX = DMA address
	ADC	AL, 0				; AL = DMA page
	MOV	BX, DX			; check that buffer offset + length does not exceed segment
	ADD	BX, CX			; test for overflow (ignore sum in BX)
	JC	FDC_DMA_BOUND		; DMA access across 64k boundary error
	CLI					; Disable interrupts
	OUT	DMA_P_C2, AL 		; set DMA Channel 2 Page Address Register (port 81H)
	XCHG	AX, DX			; AL = address low byte, AH = high byte (4)
	OUT	DMA_2_A, AL			;
	XCHG	AL, AH 			; AH = address low byte, AL = high byte (4)
	OUT	DMA_2_A, AL			;
	XCHG	AX, CX			; AL = byte/count low byte, AH = high byte (4)
	OUT	DMA_2_C, AL			;
	XCHG	AL, AH			; AH = byte/count low byte, AL = high byte (4)
	OUT	DMA_2_C, AL
	STI					; Enable interrupts
	MOV	AL, 0010B			; DMA channel 2 mask
	OUT	DMA_MASK, AL		; Unmask DMA Single Channel 2 (port 0AH)
FDC_INIT_DMA_EXIT:
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

;----------------------------------------------------------------------------;
; DMA page boundary overrun
;
FDC_DMA_BOUND:
	OR	FD_LAST_OP, FDC_ST_DMA_64K
	STC
	JMP	SHORT FDC_INIT_DMA_EXIT

FDC_INIT_DMA ENDP

;----------------------------------------------------------------------------;
; FDC_RECV: Wait for FDC ready to send and read next FDC Status byte into AL
;----------------------------------------------------------------------------;
; Timeout is 5 timer ticks = ~275ms.
;
; Input: None
; Output:
;	AL = top of FDC status stack
;	AH = 80H if error, AH preserved if success
;	CF if timeout or error
;----------------------------------------------------------------------------;
FDC_RECV PROC
	PUSH	BX
	XOR	BX, BX				; flag is 0 if RECV operation
	MOV	BH, AL				; save byte to send
	JMP	SHORT FDC_SEND_RECV

;----------------------------------------------------------------------------;
; FDC_SEND_PARAM: Wait for FDC ready and send a floppy param in AL
;----------------------------------------------------------------------------;
; Same as below except AL input is INT_1E param index
;----------------------------------------------------------------------------;
FDC_SEND_PARAM PROC
	CALL	INT_1E_PARAM 			; AL = INT_1E[AL] param

;----------------------------------------------------------------------------;
; FDC_SEND: Wait for FDC ready to receive and send a single command
;----------------------------------------------------------------------------;
; Timeout is 5 timer ticks = ~275ms.
;
; Input:
;	AL = byte to send to FDC
;
; Output:
;	AL = status register
;	AH = 80H if error, AH preserved if success
;	CF and ZF if error
;----------------------------------------------------------------------------;
FDC_SEND PROC
	PUSH	BX
	MOV	BH, AL				; save byte to send
	MOV	BL, 1					; flag is 1 if SEND operation

FDC_SEND_RECV:
	PUSH	CX
	PUSH	DX 					; call-preserve used registers

;----------------------------------------------------------------------------;
; Wait for FDC I/O direction = CPU to FDC and Data Reg Ready
;
	MOV	DX, FDC_STAT 			; port 3F4H - FDC Main Status Register
	MOV	CX, 5					; CX = # of ticks to wait
	MOV	AH, BYTE PTR TIMER_CT_L		; get starting tick counter low byte

FDC_SEND_WAIT_POLL:
	IN	AL, DX				; AL = FDC status register
	TEST	AL, AL				; is DRR = I/O to/from CPU?
	JNS	FDC_SEND_WAIT_TIMER		; if not, check if timeout has elapsed

;----------------------------------------------------------------------------;
; FDC is ready for I/O
;
	INC	DX 					; port 3F5H - FDC Command Status Register
	TEST	BL, BL				; is send or receive?
	JZ	FDC_RECV_WAIT_POLL		; jump if receive

;----------------------------------------------------------------------------;
; SEND operation
;----------------------------------------------------------------------------;
FDC_SEND_WAIT_POLL_1:
	TEST	AL, MASK FIOD			; is I/O direction = CPU to FDC (0)?
	JNZ	FDC_SEND_WAIT_TIMER		; if not, check if timeout has elapsed

;----------------------------------------------------------------------------;
; Status is ready to send
;
FDC_SEND_READY:
	MOV	AL, BH				; restore AL byte to send
	OUT	DX, AL				; send command
	JMP	SHORT FDC_WAIT_DONE		; status = success (0), CF = 0 and done

;----------------------------------------------------------------------------;
; RECEIVE operation
;----------------------------------------------------------------------------;
FDC_RECV_WAIT_POLL:
	TEST	AL, MASK FIOD			; is I/O direction = FDC to CPU (1)?
	JZ	FDC_SEND_WAIT_TIMER		; if not, check if timeout has elapsed

;----------------------------------------------------------------------------;
; Data is ready to read
;
FDC_RECV_READY:
	IN	AL, DX				; read from FDC

;----------------------------------------------------------------------------;
; Completed with success
;
FDC_WAIT_DONE:
	XOR	AH, AH 				; status = success (0), CF = 0

FDC_WAIT_EXIT:
	POP	DX
	POP	CX
	POP	BX
	RET

;----------------------------------------------------------------------------;
; Check if timeout has expired
;
FDC_SEND_WAIT_TIMER:
	MOV	AL, BYTE PTR TIMER_CT_L		; get current tick counter
	CMP	AL, AH				; still the same?
	JZ	FDC_SEND_WAIT_POLL		; loop if the same
	MOV	AH, AL				; otherwise, save new tick value to AH
	LOOPNZ FDC_SEND_WAIT_POLL		; loop until # of ticks (CX) has elapsed

FDC_WAIT_TIMEOUT:
	MOV	AH, FDC_ST_TIMEOUT 		; time out, drive not ready error
	OR	FD_LAST_OP, AH			; set flag in BDA
	STC						; set error
	JMP	SHORT	FDC_WAIT_EXIT

FDC_SEND ENDP
FDC_SEND_PARAM ENDP
FDC_RECV ENDP

;-------------------------------------------------------------------------
; FDC_WAIT_SENSE: wait for WIF, sense status and get status bytes
;-------------------------------------------------------------------------
; Output:
;	CF if error
;	AL = FDC_LAST_ST (BDA Floppy drive status)
;	AH clobbered
;-------------------------------------------------------------------------
FDC_WAIT_SENSE PROC
	CALL	FDC_WAIT_INT 			; wait for WIF
	JC	FDC_WAIT_SENSE_EXIT
	MOV	AL, FDC_CMD_SENSE			; sense Interrupt status
	CALL	FDC_SEND

;----------------------------------------------------------------------------;
; FDC_RECV_STATUS:
;----------------------------------------------------------------------------;
; Output:
;	CF if FDC read/timeout error
;	NZ if result status error
;
;	AL = FDC_LAST_ST (BDA Floppy drive status), if success
;	AH clobbered
;----------------------------------------------------------------------------;
FDC_RECV_STATUS PROC
	JC	FDC_WAIT_SENSE_EXIT		; return if timeout error
							; fall through to FDC_RECV_ALL

;----------------------------------------------------------------------------;
; FDC_RECV_ALL: Pop all status bytes from FDC to BDA
;----------------------------------------------------------------------------;
; Check for FDC errors and set FD_LAST_OP if necessary
;----------------------------------------------------------------------------;
FDC_RECV_ALL PROC
	PUSH	ES
	PUSH	CX
	PUSH	DI
	PUSH	DX
	MOV	DX, FDC_STAT
	MOV	AX, SEG _BDA
	MOV	ES, AX
	MOV	DI, OFFSET FDC_LAST_ST 		; FDC Command Status Last Result
	MOV	CX, 7					; loop up to 7 FDC bytes
FDC_RECV_ALL_LOOP:
	CALL	FDC_RECV				; AL = next byte, AH = 0 if success
	JC	FDC_RECV_ALL_DONE			; CF if failure
	STOSB						; write to BDA

;----------------------------------------------------------------------------;
; Additional delay for FDC to settle
;
		IF ARCH_TYPE EQ ARCH_TURBO
	MOV	AL, 20				; [4]
		ELSE
	MOV	AL, 10				; [4]
		ENDIF
FDC_RECV_DELAY:
	DEC	AX					; [3]
	JNZ	FDC_RECV_DELAY			; [4+16n]

;----------------------------------------------------------------------------;
; Check for additional bytes to be read from FDC registers
;
	IN	AL, DX				; DX = 03F4H
	TEST	AL, 00010000B 			; is FDC R/W command in progress flag?
	LOOPNZ FDC_RECV_ALL_LOOP		; loop until no flag or 7 bytes read
	JCXZ	FDC_RECV_CHECK_ERR 		; if all done, check for error
	XOR	AL, AL 				; otherwise, zero out rest of
	REP	STOSB					;  results in BDA
FDC_RECV_CHECK_ERR:
	MOV	AL, FDC_LAST_ST 			; AL = last FDC status byte 0
	TEST	AL, 11000000B			; check Last Command Status
FDC_RECV_ALL_DONE:
	POP	DX
	POP	DI
	POP	CX
	POP	ES
FDC_WAIT_SENSE_EXIT:
	RET
FDC_RECV_ALL ENDP
FDC_RECV_STATUS ENDP
FDC_WAIT_SENSE ENDP

;-------------------------------------------------------------------------
; FDC_WAIT_STATUS: Wait for WIF, get status bytes and check for error
;-------------------------------------------------------------------------
FDC_WAIT_STATUS PROC
	CALL	FDC_WAIT_INT 			; wait for WIF
	CALL	FDC_RECV_STATUS			; read FDC status into BDA
							; CF if FDC error, NZ if status error
	JBE	FDC_WAIT_ERR_EXIT_OK		; exit if ZF or CF error

;-------------------------------------------------------------------------
; FDC_WAIT_STATUS_ERR: Map FDC Command Status Register 1 to BDA error codes
;-------------------------------------------------------------------------
; Input:
;	AL = Last result from FDC_LAST_ST
; Output:
;	CF if error
;	AH/AL = BDA Floppy drive status
;-------------------------------------------------------------------------
FDC_WAIT_STATUS_ERR PROC
	PUSH	SI
	TEST	AL, 01000000B			; command terminated abnormally?
	MOV	AL, FDC_ST_ERR_FDC		; if not, FDC error
	JZ	FDC_WAIT_STATUS_ERR_DONE
	MOV	AH, FDC_LAST_ST[1]		; AH = last status byte 1
	TEST	AH, AH
	JZ	FDC_WAIT_STATUS_ERR_DONE	; skip if AH = 0
	MOV	SI, OFFSET FDC_ERR1_MAP
FDC_ERR_MAP_LOOP:
	LODS	BYTE PTR CS:[SI]			; fetch next error
	SHL	AH, 1					; CF if this status flag
	JC	FDC_WAIT_STATUS_ERR_DONE	; jump if flag set
	JNZ	FDC_ERR_MAP_LOOP			; loop until AH = 0
FDC_WAIT_STATUS_ERR_DONE:
	MOV	AH, AL				; AH = last result
FDC_WAIT_ERR_EXIT:
	POP	SI
	OR	FD_LAST_OP, AH			; BDA 40:41H
	STC
FDC_WAIT_ERR_EXIT_OK:
	RET

;-------------------------------------------------------------------------
; Note: Must check from most sig bit to lowest since higher
; bits are more meaningful.
;
FDC_ERR1_MAP LABEL BYTE
	DB	FDC_ST_ERR_SEC			; 80 end of cylinder
	DB	FDC_ST_ERR_FDC			; 40 unused (always zero)
	DB	FDC_ST_ERR_CRC			; 20 data error CRC
	DB	FDC_ST_DMA_OVR			; 10 DMA timeout/overrun
	DB	FDC_ST_ERR_FDC			; 08 unused (always zero)
	DB	FDC_ST_ERR_SEC			; 04 Sector Not Found
	DB	FDC_ST_ERR_WP			; 02 Write Protect
	DB	FDC_ST_ERR_MARK			; 01 Address mark not found or bad sector

FDC_WAIT_STATUS_ERR ENDP
FDC_WAIT_STATUS ENDP

;----------------------------------------------------------------------------;
; Retrieve a parameter value from the DBT by index
;----------------------------------------------------------------------------;
; Input:
;	AL = parameter index (bounds not checked)
; Output:
;	AL = byte
;
; Size: 14 bytes
;----------------------------------------------------------------------------;
INT_1E_PARAM PROC
	PUSH	DS
	PUSH	BX
	XOR	BX, BX 				; BX = IVT
	MOV	DS, BX 				; DS = IVT
			ASSUME DS:_IVT
	LDS	BX, _INT_1EH			; set DS:BX to INT_1E
	XLAT 						; AL = byte
	POP	BX
	POP	DS
INT_1E_PARAM_DONE:
	RET
INT_1E_PARAM ENDP

;
; 1 BYTE HERE
;
BYTES_HERE	INT_0E

;----------------------------------------------------------------------------;
; INT 0EH - Floppy Disk Interrupt IRQ6
;----------------------------------------------------------------------------;
; This interrupt is issued upon floppy disk I/O completion and is
;  responsible for updating the floppy disk interrupt flag at 40:3E, bit 7.
;----------------------------------------------------------------------------;
		ORG 0EF57H
INT_0E PROC
		ASSUME DS:_BDA
	STI
	PUSH	AX
	PUSH	DS
	MOV	AX, SEG _BDA 			; DS = BDA segment
	MOV	DS, AX
	OR	FD_CAL_ST, MASK FWIF		; turn on working interrupt flag
	MOV	AL, INT_EOI 			; End of Interrupt OCW
	OUT	INT_P0, AL				; write EOI to port 0
	POP	DS
	POP	AX
	IRET
INT_0E ENDP

;----------------------------------------------------------------------------;
; FDC_WAIT_INT: Wait for BDA Working Interrupt Flag from FDC
;----------------------------------------------------------------------------;
; Input: DS = BDA
; Output: CF if timeout
;----------------------------------------------------------------------------;
FDC_WAIT_INT PROC
	STI						; ensure interrupts are on
	PUSH	AX 					; call preserve regs
	PUSH	CX
	MOV	CX, 2 * (1000/55) + 1		; timeout ~2 sec (37 ticks)
FDC_WAIT_INT_LOOP1:
	MOV	AX, TIMER_CT_L			; AX = time ticks
FDC_WAIT_INT_LOOP2:
	TEST	FD_CAL_ST, MASK FWIF 		; check for WIF in FD_CAL_ST (3EH)
	JNZ	FDC_WAIT_INT_OK			; if so, exit
			IF FDC_HTL_WAIT GT 0
	HLT						; wait for any INT
			ELSE
	NOP						; allow extra time for INTs
			ENDIF
	CMP	AX, TIMER_CT_L			; has timer tick changed?
	JZ	FDC_WAIT_INT_LOOP2		; if not, wait for next INT
	LOOP	FDC_WAIT_INT_LOOP1		; decrement tick counter and resume loop
	OR	FD_LAST_OP, FDC_ST_TIMEOUT 	; FDC result set time out, drive not ready
	STC
	JMP	SHORT FDC_WAIT_INT_DONE
FDC_WAIT_INT_OK:
	AND	FD_CAL_ST, NOT MASK FWIF 	; clear working interrupt flag
FDC_WAIT_INT_DONE:
	POP	CX
	POP	AX
	RET
FDC_WAIT_INT ENDP

;-------------------------------------------------------------------------
; FDC_RECAL: recalibrate drive, if necessary
;-------------------------------------------------------------------------
; Input:
;	DL = drive to recalibrate
; Output:
;	CF if error
;
; AX clobbered
;-------------------------------------------------------------------------
FDC_RECAL PROC
	PUSH	CX
	CALL	FDC_MOTOR_ON
	MOV	CL, DL 				; move to CL for shift
	AND	CL, 0011B 				; mask just drive number in CL
	MOV	AL, 0001B 				; AL shift to FDC drive # bit
	SHL	AL, CL 				; shift drive flags
	TEST	AL, FD_CAL_ST 			; 0 means drive is uncalibrated
	JNZ	FDC_RECAL_DONE 			; if drive is calibrated, exit
	MOV	CH, AL 				; CH = drive bits
	MOV	AL, FDC_CMD_RECAL 		; recalibrate command (07H)
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_RECAL_ERR
	MOV	AL, CL 				; AL = drive number
	CALL	FDC_SEND 				; send command, CF if error
	;JC	FDC_RECAL_ERR
	CALL	FDC_WAIT_SENSE 			; wait for WIF, sense and get status in AL
	JC	FDC_RECAL_ERR
	XOR 	AL, 01100000b			; select interesting bits
	TEST	AL, 01100000b			; ZF = abnormal term. AND seek complete
	JZ	FDC_RECAL_ERR
	OR	FD_CAL_ST, CH 			; mark drive as calibrated (and CLC)
FDC_RECAL_ERR:
FDC_RECAL_DONE:
	POP	CX
	RET
FDC_RECAL ENDP

INT_13 ENDP

;
; 1 BYTE HERE
;
BYTES_HERE	INT_1E

;----------------------------------------------------------------------------;
; INT 1E - Disk Initialization Parameter Table Vector
;----------------------------------------------------------------------------;
; Provides a "pluggable" method to allow additional disk ROMs or DOS to 
; replace this table.
;
;  Head Step Rate = 0CH = 12ms
;  Head Unload Time = 0FH (16ms increments) = 240ms?
;  Head Load Time = 01H (2ms increments) = 2ms
;  MFM = 2
;  Bytes Per Sector = 512
;  Sectors Per Track = 8
;  Write Gap = 02AH
;  Format Gap = 050H
;
; https://stanislavs.org/helppc/dbt.html
; https://stanislavs.org/helppc/765.html
; https://stanislavs.org/helppc/int_1e.html
;----------------------------------------------------------------------------;
		ORG  0EFC7H
INT_1E LABEL BYTE
	DB  0CFH 		; 00 step-rate time SRT (0CH), head unload time HUT (0FH)
	DB  00000010B 	; 01 head load time HLT (01H), DMA mode ND (0)
	DB  37 		; 02 timer ticks to wait before disk motor shutoff
	DB  2 		; 03 bytes per sector (0=128, 1=256, 2=512, 3=1024)
	DB  8 		; 04 sectors per track (last sector number)
	DB  02AH 		; 05 inter-block gap length/gap between sectors
	DB  0FFH 		; 06 data length, if sector length not specified
	DB  050H 		; 07 gap length between sectors for format
	DB  0F6H 		; 08 fill byte for formatted sectors
	DB  25 		; 09 head settle time in milliseconds
	DB  4 		; 0A motor startup time in eighths of a second
L_INT_1E EQU $-INT_1E

;----------------------------------------------------------------------------;
; INT 17 - Printer BIOS Services
;----------------------------------------------------------------------------;
;	INT 17,0   Print character
;	INT 17,1   Initialize printer port
;	INT 17,2   Read printer port status
;
; https://www.stanislavs.org/helppc/ports.html
; https://en.wikipedia.org/wiki/Parallel_port#IBM_PC_implementation
; http://www.techhelpmanual.com/907-parallel_printer_adapter_ports.html
;----------------------------------------------------------------------------;
; Things you must do (on all calls):
; - Verify printer is within range 0-2.
; - Verify printer index is detected and get I/O address.
; - Return AH = 0 if any of the above are not met.
; - Do the function call
; - Get port status and return in AH for any valid calls.
;
; Things you should do:
; - Get installed printer count via INT 11H
;
;----------------------------------------------------------------------------;
		ORG 0EFD2H
INT_17 PROC
		ASSUME DS:_BDA
	STI 						; enable interrupts
	PUSH	DX					; call-preserve DX
	CMP	DX, 2					; is greater than 2?
	JA	INT_17_EXIT 			; if so, exit
	PUSH	DI 					; call-preserve working regs
	PUSH	CX
	PUSH	AX
	PUSH	DS
	MOV	CX, SEG _BDA 			; CH = 0, CL = 40H
	MOV	DS, CX				; DS = BDA
	MOV	DI, DX 				; DI = LPT port index (0-2)
	MOV	CL, LPT_TIME[DI]			; CX = port timeout
	SHL	DI, 1 				; convert to word-aligned index
	MOV	DX, LPT_ADDR[DI] 			; DX = data port address
	POP	DS 					; restore DS
	TEST	DX, DX 				; is port index valid (detected)?
	JZ	INT_17_DONE 			; if not, exit
	DEC	AH
	JZ	INT_17_1				; AH = 1 then init
	JG	INT_17_2	 			; AH = 2 then status
							; otherwise fall through to print

;----------------------------------------------------------------------------;
; AH = 0 - Print Character
;----------------------------------------------------------------------------;
; Write character and returns status
;
;	AH = -1 (not 0)
;	AL = character to print
;	CX = timeout "value" (aparently this is approx the number of 64k loops)
;	DX = LPT data port (278, 378, 3BC)
;
;	on return:
;	AH = printer status, see AH = 2
;----------------------------------------------------------------------------;
INT_17_0:
	OUT	DX, AL			; write the character to data port
	INC	DX				; DX to status port
INT_17_0_TIMEOUT_LOOP:
	XOR	DI, DI			; set abitrary timeout counter
INT_17_0_BUSY_LOOP:
	IN	AL, DX			; read status port
	TEST	AL, MASK LPBZ 		; printer busy?
	JNZ	INT_17_0_OK			; if not, toggle strobe pin and exit
	DEC	DI
	JNZ	INT_17_0_BUSY_LOOP
	LOOP	INT_17_0_TIMEOUT_LOOP 	; loop BDA/LPT timeout value
	OR	AL, MASK LPTO		; printer timed out - set flag
	JMP	SHORT INT_17_2_STATUS_2	; exit with status in AL
INT_17_0_OK:
	MOV	AL, 00001101B 		; /strobe pin HIGH
	INC	DX 				; DX = control port
	PUSH	DX				; I/O delay
	OUT	DX, AL
	POP	DX				; I/O delay
	MOV	AL, 00001100B		; /strobe pin LOW
	OUT	DX, AL
	DEC	DX 				; DX = status port
	JMP	SHORT INT_17_2_STATUS	; read status and return

;----------------------------------------------------------------------------;
; AH = 1 - Initialize printer port
;----------------------------------------------------------------------------;
;	AH = 0 (not 1)
;	DX = LPT data port (278, 378, 3BC)
;
;	on return:
;	AH = status, see AH = 2
;----------------------------------------------------------------------------;
INT_17_1:
	MOV	AL, 1000B			; printer reads output = 1
	INC	DX
	INC	DX				; DX = control port
	OUT	DX, AL			; send to control port
	MOV	CH, 8				; delay 800H-ish loops
	IO_DELAY 				; wait, then CX = 0
	OR	AL, 0100B			; initialize printer = 1
	OUT	DX, AL			; send to control port
	IO_DELAY_SHORT 			; small delay just in case
	DEC	DX 				; reset to data port
	DEC	DX				; and fall through to AH = 2

;----------------------------------------------------------------------------;
; AH = 2 - Read printer port status
;----------------------------------------------------------------------------;
; Return status of specified printer port
;
;	AH = 1 (not 2)
;	DX = LPT data port (278, 378, 3BC)
;
;	on return:
;	AH = status:
;
;		|7|6|5|4|3|2|1|0|  Printer status bits
;		 | | | | | | | `---- time out		(always 0)
;		 | | | | | `------- unused
;		 | | | | `-------- I/O error		Pin 15
;		 | | | `--------- selected		Pin 13
;		 | | `---------- out of paper		Pin 12
;		 | `----------- acknowledge		Pin 10
;		 `------------ not busy			/Pin 11
;
; PRN_STAT RECORD	LPBZ:1,LPACK:1,LPOP:1,LPSEL:1,LPIO:1,LPX:2,LPTO:1
;----------------------------------------------------------------------------;
INT_17_2:
	INC	DX 				; DX to status port
INT_17_2_STATUS:
	IN	AL, DX			; AL = status
	AND	AL, 11111000B		; mask time-out pins
INT_17_2_STATUS_2:
	XOR	AL, MASK LPACK OR MASK LPIO ; acknowledge and error are active low
	MOV	CH, AL			; save status to CH so AL can be restored
INT_17_DONE:
	POP	AX				; restore AL
	MOV	AH, CH			; AH = status
	POP	CX
	POP	DI
INT_17_EXIT:
	POP	DX
	IRET
INT_17 ENDP

			IF ARCH_TYPE EQ ARCH_TURBO
;----------------------------------------------------------------------------;
; Handle Turbo speed mode toggle from INT 09h keyboard interrupt
;----------------------------------------------------------------------------;
; Size: 15 bytes
;----------------------------------------------------------------------------;
INT_KB_TOGGLE_TURBO PROC
	IN	AL, PPI_B
	TEST	AL, MASK PBTB				; is in Turbo mode?
	JNZ	INT_KB_TURBO_IS_ON			; if so, only one meep since
	CALL	MEEP						;  switching to low speed
INT_KB_TURBO_IS_ON:
	CALL	MEEP
	JMP	TOGGLE_TURBO
INT_KB_TOGGLE_TURBO ENDP
			ENDIF

;
; 0 BYTES HERE
;
BYTES_HERE	INT_10_JMP

;----------------------------------------------------------------------------;
; INT 10h - Function Jump Table
;----------------------------------------------------------------------------;
		ORG 0F045H			; 32 bytes (use INT_10_JMP_ORG for ORG)
INT_10_JMP LABEL WORD
	DW	OFFSET INT_10_0		; AH = 0 - Set video mode
	DW	OFFSET INT_10_1		; AH = 1 - Set cursor type
	DW	OFFSET INT_10_2		; AH = 2 - Set cursor position
	DW	OFFSET INT_10_3		; AH = 3 - Read cursor position
	DW	OFFSET INT_10_RET		; AH = 4 - Read light pen (not supported)
	DW	OFFSET INT_10_5		; AH = 5 - Select active display page
	DW	OFFSET INT_10_6		; AH = 6 - Scroll active page up
	DW	OFFSET INT_10_7		; AH = 7 - Scroll active page down
	DW	OFFSET INT_10_8		; AH = 8 - Read character and attribute at cursor
	DW	OFFSET INT_10_9		; AH = 9 - Write character and attribute at cursor
	DW	OFFSET INT_10_A		; AH = A - Write character at current cursor
	DW	OFFSET INT_10_B		; AH = B - Set color palette
	DW	OFFSET INT_10_C		; AH = C - Write graphics pixel at coordinate
	DW	OFFSET INT_10_D		; AH = D - Read graphics pixel at coordinate
	DW	OFFSET INT_10_E		; AH = E - Write text in teletype mode
	DW	OFFSET INT_10_F		; AH = F - Get current video state
INT_10_JMP_ORG	EQU	INT_10-($-INT_10_JMP)

;----------------------------------------------------------------------------;
; INT 10h - Video BIOS Services
;----------------------------------------------------------------------------;
; BIOS Interface to CGA/MDA display adapters.
;----------------------------------------------------------------------------;
		ORG 0F065H
INT_10 PROC
	STI					; enable interrupts
	CMP	AH, 15			; function > 15?
	JA	INT_10_IRET			; exit if function not valid
	PUSH	ES				; always preserve these registers
	PUSH	DS
	PUSH	DI
	MOV	DI, SEG _BDA		; DS = BDA segment
	MOV	DS, DI
	MOV	DI, AX			; save AX
	XCHG	AH, AL			; AL = function, AH = video mode
	CLD					; string instructions forward direction
	SHL	AL, 1				; word align index
	CBW					; AX = jump index
	XCHG	AX, DI			; restore AX, DI = jump offset
	CALL	CS:INT_10_JMP[DI]
INT_10_DONE:
	POP	DI
	POP	DS
	POP	ES
INT_10_IRET:
	IRET

;----------------------------------------------------------------------------;
; Is Current video mode text or GFX?
;----------------------------------------------------------------------------;
; Input:
; 	DS = BDA (040h)
; Return:
;	AL = current video mode
; 	ZF = 0 if CGA GFX (modes 4-6)
;	ZF = 1 if CGA/MDA Text (modes 0-3 and 7)
;	CF = 1 if MDA
;----------------------------------------------------------------------------;
INT_10_IS_TXT PROC
	MOV	AL, VID_MODE
	CMP	AL, 7				; ZF if mode MDA
	CMC					; CF if MDA
	JZ	INT_10_IS_TXT_DONE
	TEST	AL, 0100B			; NZ if GFX modes 4,5,6?
INT_10_IS_TXT_DONE:
	RET
INT_10_IS_TXT ENDP

;----------------------------------------------------------------------------;
; Is Current video CGA 80 col?
;----------------------------------------------------------------------------;
; Return:
;	ZF = 1 if mode is 2 or 3
;	ZF = 0 all others
;----------------------------------------------------------------------------;
INT_10_IS_CGA80 PROC
	PUSH	AX
	PUSH	DS
	MOV	AX, SEG _BDA
	MOV	DS, AX
	MOV	AL, VID_MODE
	CMP	AL, 2				; is mode 2?
	JZ	INT_10_IS_CGA80_DONE
	CMP	AL, 3				; is mode 3?
INT_10_IS_CGA80_DONE:
	POP	DS
	POP	AX
INT_10_0_RET:
	RET
INT_10_IS_CGA80 ENDP

;
; 1 BYTE HERE
;
BYTES_HERE	INT_1D

;----------------------------------------------------------------------------;
; INT 1D - Video mode register value table 
;----------------------------------------------------------------------------;
; https://stanislavs.org/helppc/6845.html
;----------------------------------------------------------------------------;
		ORG 0F0A4H					; 116 bytes
INT_1D PROC

; 40x25 CGA text
INT_1D_40		VPT	<38H,28H,2DH,0AH,1FH,06H,19H,1CH,02H,07H,06H,07H>
O_INT_1D_40		EQU	INT_1D_40-INT_1D		; 40x25 mode data offset

; 80x25 CGA text
INT_1D_80		VPT	<71H,50H,5AH,0AH,1FH,06H,19H,1CH,02H,07H,06H,07H>
O_INT_1D_80		EQU	INT_1D_80-INT_1D		; 80x25 mode data offset

; 320x200 CGA graphics
INT_1D_GFX		VPT	<38H,28H,2DH,0AH,7FH,06H,64H,70H,02H,01H,06H,07H>
O_INT_1D_GFX	EQU	INT_1D_GFX-INT_1D		; 320x200 mode data offset

; MDA text
INT_1D_MDA		VPT	<61H,50H,52H,0FH,19H,06H,19H,19H,02H,0DH,0BH,0CH>
O_INT_1D_MDA	EQU	INT_1D_MDA-INT_1D		; MDA mode data offset

INT_1D ENDP

;----------------------------------------------------------------------------;
; INT 10,0 - Set video mode
;----------------------------------------------------------------------------;
; AL = video mode:
;   0000  00  M 40x25 B/W text (CGA)
;   0001  01  C 40x25 16 color text (CGA)
;   0010  02  M 80x25 16 shades of gray text (CGA)
;   0011  03  C 80x25 16 color text (CGA)
;   0100  04  C 320x200 4 color graphics (CGA)
;   0101  05  C 320x200 4 color graphics (CGA)
;   0110  06  M 640x200 B/W graphics (CGA)
;   0111  07  M 80x25 Monochrome text (MDA,HERC)
;----------------------------------------------------------------------------;
; Things you must do:
; 	1. Check that the new video mode is valid: 0-7. For MDA, the mode
;		will always be 7.
;	2. Clear the video BDA block data
;	3. Determine the type of adapter from motherboard switches
;	4. Disable the adapter to reprogram it.
;	5. Based on new input mode and MB switches, determine:
;		- Adapter base I/O port (03B4H for MDA, 03D4H for CGA)
;		- RAM base segment (0B000H for MDA, 0B800H for CGA)
;		- RAM size (16K for CGA gfx, 4K for 80x25 text, 2K for 40x25 text)
;		- RAM fill data (0 for gfx, space char with attribute 7 for text)
;		- Corresponding entry from INT 1DH CRTD table for new video mode
;		- Corresponding mode byte from CRT_MODE table
;	6. Clear regen RAM by filling with data from above
;	7. Write data from CRTD table to adapter registers to set mode
;	8. Write CGA palette register
;	9. Enable adapter with new mode byte
;
;----------------------------------------------------------------------------;
INT_10_0 PROC
	CMP	AL, 7					; is new video page > 7?
	JA	INT_10_0_RET			; if so, not valid, return
	PUSH	AX
	PUSH	BX
	PUSH	DX
	PUSH	BP
	PUSH	CX
	PUSH	SI
	XCHG	AX, BX				; BL = new video mode

;----------------------------------------------------------------------------;
; Clear all video data in BDA
;
	XOR	AX, AX
	MOV	CX, L_VID_BDA / 2			; Video data in BDA (in WORDs)
	MOV	DI, OFFSET VID_MODE		; start with VID_MODE (49H)
	PUSH	DS
	POP	ES					; ES = BDA
	REP	STOSW

;----------------------------------------------------------------------------;
; Determine video adapter type and new mode and re-program 6845
;
	MOV	AL, BYTE PTR EQUIP_FLAGS
	AND	AL, MASK VIDM			; isolate video switches
	CMP	AL, 00110000B			; is MDA? (3 SHL 4 or 30H)
	MOV	AL, 0					; 0 = CGA disable video signal
	MOV	SI, O_INT_1D_80			; SI = CGA 80 CRTD offset
	MOV	BH, VID_DEF_COLS			; default 80 columns
	MOV	CH, HIGH OFFSET MDA_MEM		; Total MDA video memory = 1000H (4K)
	MOV	VID_BUF_SZ, CX			; MDA/CGA 80x25 page size = 1000H (4K)
	MOV	DI, 0700H OR VID_SP		; fill memory with attr 7 and space
	JNZ	INT_10_0_IS_CGA
	INC	AX					; 1 = MDA disable video signal value
	MOV	BP, SEG _MDA_MEM			; BP = MDA memory segment (0B000H)
	MOV	DX, MDA_CTRL			; MDA Mode Select Register (03B8H)
	MOV	BL, 7					; only valid MDA display mode is 7
	MOV	SI, O_INT_1D_MDA			; SI = MDA CRTD offset
	JMP	SHORT INT_10_0_DETECT_DONE
INT_10_0_IS_CGA:
	MOV	CH, HIGH OFFSET CGA_MEM		; Total CGA video memory = 4000H (16K)
	MOV	DX, CGA_CTRL			; CGA Mode Select Register (03D8H)
	MOV	BP, SEG _CGA_MEM			; BP = CGA memory segment (0B800H)
	TEST	BL, 0100B				; text or gfx mode?
	JZ	INT_10_0_IS_CGA_TEXT		; jump if text
INT_10_0_IS_CGA_GFX:
	MOV	SI, O_INT_1D_GFX			; SI = CGA GFX CRTD offset
	MOV	VID_BUF_SZ, CX			; CGA gfx page size = 4000H (16K)
	XOR	DI, DI				; DI = memory fill 0's
	TEST	BL, 0010B				; is 80 or 40 col text?
	JNZ	INT_10_0_DETECT_DONE		; jump if 80
	JMP	SHORT INT_10_0_IS_40_COL	; else set 40 columns
INT_10_0_IS_CGA_TEXT:
	TEST	BL, 0010B				; is 80 or 40 col text?
	JNZ	INT_10_0_DETECT_DONE		; jump if 80
	SHR	BYTE PTR VID_BUF_SZ[1], 1	; CGA 40x25 page size = 800H (2K)
	;MOV	BYTE PTR VID_BUF_SZ+1, HIGH OFFSET CGA_MEM_40	
	XOR	SI, SI				; SI = CGA 40 CRTD offset (00H)
INT_10_0_IS_40_COL:
	SHR	BH, 1					; BH = 40 columns
INT_10_0_DETECT_DONE:
	OUT	DX, AL				; disable video
	MOV	ES, BP				; ES = video memory segment
	SUB	DL, 4					; DX = 6845 index register port
	MOV	VID_PORT, DX			; write BDA video I/O port
	MOV	WORD PTR VID_MODE, BX		; write BDA mode and cols
	MOV	VID_MEM_SEG, BP			; write video segment for later

;----------------------------------------------------------------------------;
; Fill video regen/memory
;
	XCHG	AX, DI				; AX = fill byte
	XOR	DI, DI				; start at offset 0
	SHR	CX, 1					; WORD size counter
	REP	STOSW

;----------------------------------------------------------------------------;
; Write CRTC data to 6845 registers
;
	PUSH	DS					; save DS = BDA
	XOR	AX, AX
	MOV	VID_SEG, AX				; page 1 offset = 0
	MOV	VID_PAGE, AL			; video page 1 = 0
	MOV	DS, AX				; DS = IVT
			ASSUME DS:_IVT
	LDS	BP, _INT_1DH			; DS:BP = BIOS:INT_1D
	MOV	DI, DS:[BP+SI+0AH]		; DI = cursor type
	MOV	CL, 10H				; size of CRTC data
INT_10_0_CRTC_LOOP:
	MOV	AH, BYTE PTR DS:[BP+SI]		; AH = next byte from table
	OUT	DX, AX				; write AH to register index AL
	INC	AX					; next register index
	INC	SI					; next byte in table
	LOOP	INT_10_0_CRTC_LOOP

;----------------------------------------------------------------------------;
; Send mode and color bytes to 6845
;
	XCHG	AX, BX				; AL = new video mode
	CMP	AL, 6					; is CGA color gfx mode?
	MOV	AH, 00111111B			; use for 640x200 mode 6
	JZ	INT_10_0_COLOR_BYTE		; jump if it
	MOV	AH, 00110000B			; otherwise use this
INT_10_0_COLOR_BYTE:
	MOV	BX, OFFSET CRT_MODE
	XLAT						; AL = control byte data
			ASSUME DS:_BDA
	POP	DS					; DS = BDA
	ADD	DL, 4					; DX = control reg
	MOV	WORD PTR VID_MODE_REG, AX	; write mode and color to BDA
	OUT	DX, AX				; write mode and color to 6845
	XCHG	AX, DI				; AX = cursor bytes from CRTC table
	XCHG	AH, AL				; convert endian for cursor bytes
	MOV	VID_CURS_TYPE, AX			; write cursor type to BDA
	POP	SI
	POP	CX
	POP	BP
	POP	DX
	POP	BX
	POP	AX
INT_10_RET:
	RET
INT_10_0 ENDP

;----------------------------------------------------------------------------;
; INT 10,1 - Set cursor type
;----------------------------------------------------------------------------;
; Input:
;	CH = cursor starting scan line (cursor top) (low order 5 bits)
;	CL = cursor ending scan line (cursor bottom) (low order 5 bits)
;----------------------------------------------------------------------------;
INT_10_1 PROC
	PUSH	DX
	XCHG	AX, DI			; save AX
	MOV	VID_CURS_TYPE, CX		; write new cursor to BDA
	MOV	AL, 0AH			; AL = Cursor start index (scan line)
	MOV	AH, CH			; CH = cursor starting scan line (top)
	MOV	DX, VID_PORT		; DX = 6845 index register port
	OUT	DX, AX			; write AH to 6845 reg index in AL
	INC	AX				; AL = Cursor end index (scan line)
	MOV	AH, CL			; CL = cursor ending scan line (bottom)
	OUT	DX, AX			; write AH to 6845 reg index in AL
	XCHG	AX, DI			; restore AX
	POP	DX
	RET
INT_10_1 ENDP

;----------------------------------------------------------------------------;
; INT 10,2 - Set cursor position
;----------------------------------------------------------------------------;
; Input:
;	AH = 02
;	BH = page number (0 for graphics modes)
;	DH = row
;	DL = column
;----------------------------------------------------------------------------;	
; Things you must do:
;	1. Update the BDA Cursor position (50H-5FH) with the new video page
;		with the new cursor position
;	2. Calculate the memory address of the cursor's position, and set it
;		to the 6845 Cursor address register
;
; Things you should do:
;	- Make sure page number is valid for adapter type and current mode
;
;----------------------------------------------------------------------------;	
INT_10_2 PROC
	PUSH	AX
	MOV	AL, BH			; AL = new video page
	CMP	AL, 7				; is new video page > 7?
	JA	INT_10_2_DONE		; if so, not valid, return

;----------------------------------------------------------------------------;
; 1. Set cursor position in BDA
;
	CBW					; AX = page number
	XCHG	AX, DI			; DI = page number
	SHL	DI, 1				; word align index
	MOV	VID_CURS_POS[DI], DX	; write to page cursor position in BDA
	CMP	VID_PAGE, BH		; is this the current page?
	JNZ	INT_10_2_DONE		; if not, do nothing and exit
	PUSH	BX
	PUSH	DX

;----------------------------------------------------------------------------;
; 2. Set cursor position in 6845 Cursor address register
;
INT_10_SET_CUR_OFFSET:
	MOV	AL, BYTE PTR VID_COLS	; AL = screen cols
	MUL	DH				; AX = row * screen cols
	XOR	DH, DH			; DX = col
	ADD	AX, DX			; AX = ( row * screen cols ) + col
						; AX = byte offset for cursor position to page memory
	MOV	BX, VID_SEG
	SHR	BX, 1				; byte align 
	ADD	BX, AX
	MOV	AL, 0EH			; 6845 Cursor address register
	MOV	AH, BH			; Cursor address (MSB)
	MOV	DX, VID_PORT
	OUT	DX, AX			; write AH to index AL
	INC	AX				; AL = 0FH
	MOV	AH, BL			; Cursor address (LSB)
	OUT	DX, AX			; write AH to index AL
	POP	DX
	POP	BX
INT_10_2_DONE:
	POP	AX
	RET
INT_10_2 ENDP

;----------------------------------------------------------------------------;
; INT 10,3 - Read cursor position and Size
;----------------------------------------------------------------------------;
; Input:
;	AH = 03
;	BH = video page
; Return:
;	CH = cursor starting scan line (low order 5 bits)
;	CL = cursor ending scan line (low order 5 bits)
;	DH = row
;	DL = column
;----------------------------------------------------------------------------;
INT_10_3 PROC
	PUSH	AX
	MOV	AL, BH			; AL = video page
	CBW					; AX = video page
	XCHG	AX, DI			; DI = video page
	SHL	DI, 1				; word align index
	MOV	DX, VID_CURS_POS[DI]
	MOV	CX, VID_CURS_TYPE
	POP	AX
	RET
INT_10_3 ENDP

;----------------------------------------------------------------------------;
; INT 10,5 - Select active display page
;----------------------------------------------------------------------------;
; Input:
;	AH = 05
;	AL = new page number
;----------------------------------------------------------------------------;
; Things you must do:
;	1. Write the new page number to BDA (40:62H)
;	2. Calculate new regen buffer page offset and update BDA and
;		6845 Start address register
;	3. Calculate the memory address of the cursor's position, and set it
;		to the 6845 Cursor address register
;
; Things you should do:
;	- Bounds check that page number is valid for adapter and current mode?
;----------------------------------------------------------------------------;
INT_10_5 PROC
	PUSH	AX
	PUSH	BX
	PUSH	DX

;----------------------------------------------------------------------------;
; 1. Write the new page number to BDA (40:62H).
;
	MOV	VID_PAGE, AL
	CBW					; AX = video page
	XCHG	AX, DI			; DI = page number (save for later)

;----------------------------------------------------------------------------;
; 2. Calculate new regen buffer page offset and update BDA and 
;	6845 Start address register
;
	MOV	AX, VID_BUF_SZ		; AX = Size of video regen buffer (bytes)
	MUL	DI				; AX = offset of start of page regen buffer
	MOV	VID_SEG, AX			; write to BDA
	SHR	AX, 1				; video segment byte-indexed
	MOV	BL, AL			; AH = Start address (MSB), BL = (LSB)
	MOV	AL, 0CH			; 6845 Start address register
	MOV	DX, VID_PORT		; 6845 I/O port address
	OUT	DX, AX			; write AH (MSB) to index AL
	INC	AX				; AL = 0DH
	MOV	AH, BL			; AH = Start address (LSB)
	OUT	DX, AX			; write AH (LSB) to index AL

;----------------------------------------------------------------------------;
; 3. Set cursor position in 6845 Cursor address register
;
	SHL	DI, 1				; get the current cursor position
	MOV	DX, VID_CURS_POS[DI]	; DH/DL = cursor position on current page
	JMP	INT_10_SET_CUR_OFFSET	; write it to the new page's offset on 6845

INT_10_5 ENDP

;----------------------------------------------------------------------------;
; INT 10,7 - Scroll active page down
;----------------------------------------------------------------------------;
; Input:
;	AL = number of lines to scroll, previous lines are
;	     blanked, if 0 or AL > screen size, window is blanked
;	BH = attribute to be used on blank line
;	CH = row of upper left corner of scroll window
;	CL = column of upper left corner of scroll window
;	DH = row of lower right corner of scroll window
;	DL = column of lower right corner of scroll window
;----------------------------------------------------------------------------;
;
;   0000  00  M 40x25 B/W text (CGA)
;   0001  01  C 40x25 16 color text (CGA)
;   0010  02  M 80x25 16 shades of gray text (CGA)
;   0011  03  C 80x25 16 color text (CGA)
;   0100  04  C 320x200 4 color graphics (CGA)
;   0101  05  C 320x200 4 color graphics (CGA)
;   0110  06  M 640x200 B/W graphics (CGA)
;   0111  07  M 80x25 Monochrome text (MDA)
;
; References and Info Sources:
;  "PC System Programming", Tischer
;  "Programmer's Guide to PC Video Systems", Second Edition, Wilton
;  https://github.com/joncampbell123/dosbox-x/blob/master/src/ints/int10_char.cpp
;  https://github.com/joncampbell123/dosbox-x/issues/256
;  https://www.seasip.info/VintagePC/cga.html
;  https://www.reenigne.org/blog/crtc-emulation-for-mess/
;  (many other posts and articles...)
;----------------------------------------------------------------------------;
; Things you must do:
; 	1. Calculate coordinates of existing rectangle and new rectangle.
;	2. Convert to memory video RAM addresses
;	3. If CGA 80 col, disable video during video RAM operations
;	4. If rows to scroll > 0, copy each row, starting at the left column.
;	   If scroll up, start from the top of the overlapping area and copy
;	   downward. If scroll down, start at the bottom and copy upward.
;	5. If rows to scroll > height of rectangle, fill the remaining rows
;	   with spaces.
;
;----------------------------------------------------------------------------;
; NOTE: The original XT BIOS (and maybe clones) appear to have a bug where
; if the lines to scroll (AL) is greater than the height of the rectangle
; it will scroll incorrectly.
; TODO: Fix this "bug" or be consistent with XT behavior?
;----------------------------------------------------------------------------;
INT_10_7 PROC
	STD					; Set direction flag

;----------------------------------------------------------------------------;
; INT 10,6 - Scroll active page up
;----------------------------------------------------------------------------;
; Input: same as INT 10,7 above
;----------------------------------------------------------------------------;
INT_10_6 PROC

	PUSH	AX				; call-preserve these registers
	PUSH	BX
	PUSH	SI
	PUSH	BP

	MOV	SI, VID_MEM_SEG		; video/regen RAM segment (B800 or B000)
	MOV	ES, SI

;----------------------------------------------------------------------------;
; Register Check:
;	AH = saved flags - ZF if scroll up
;	AL = number of rows to scroll
;	BH = attribute to be used on blank line
;	BL = scratch
;	CH = row of upper left corner of scroll window
;	CL = column of upper left corner of scroll window
;	DH = row of lower right corner of scroll window
;	DL = column of lower right corner of scroll window
;
	CMP	AH, 6				; is scroll up?
	LAHF					; save ZF if scroll up
	MOV	BP, AX			; save original AL / AH flags
	MOV	DI, DX			; save original DX
	JNZ	INT_10_CHECK_BOUNDS	; jump if scroll down

;----------------------------------------------------------------------------;
; On scroll up, the new rectangle to scroll is above the old one so start the
; bottom left of the new rectangle at the top left of the old one. This 
; will be later adjusted by the number of rows to scroll.
;
	MOV	DX, CX			; if scroll up, DX becomes "top"

;----------------------------------------------------------------------------;
; Make sure lower right column does not exceed screen width
;
INT_10_CHECK_BOUNDS:
	MOV	AL, BYTE PTR VID_COLS	; AL = video mode columns
	CMP	DL, AL			; is rect right column > screen columns?
	JB	INT_10_BOUNDS_OK
	MOV	DL, AL			; number of screen columns (80 or 40)
	DEC	DX				; fixup for 0-based column index (0-79, etc)
INT_10_BOUNDS_OK:
	MUL	DH				; AX = memory offset of col 0 of new bottom row
	MOV	DH, AL			; save AL

;----------------------------------------------------------------------------;
; Is graphics mode?
;
	CALL	INT_10_IS_TXT		; NZ if CGA GFX, ZR if CGA/MDA Text
	MOV	AL, DH			; restore AL
	MOV	DH, 0				; DX = lower right column position
	JNZ	INT_10_SCR_GFX

;----------------------------------------------------------------------------;
; Scroll in text mode
;----------------------------------------------------------------------------;
; To calculate scroll memory offsets:
;
;  rect_height = rect_height + 1
;  next_row = screen_cols - rect_width
;
;  if scroll down:
; 	rect_height = - rect_height
;	next_row = - next_row
;
;  new_top = old_top - rect_height
;  new_bottom = old_bottom - rect_height
;
INT_10_SCR_TXT:
	PUSH	DS				; save BDA data SEG
	ADD	DX, AX			; DX = byte offset of new bottom row and col
	SHL	DX, 1				; WORD-align memory offset
	ADD	DX, VID_SEG			; DX = memory offset bottom row/col in video page
	MOV	SI, DX			; SI = memory offset of new rect bottom (midpoint)
	XCHG	DI, DX			; DI = new rect bottom, DX = row/col pos.
	SUB	DX, CX			; DH = rect height (rows), DL = rect width (cols)
	MOV	CX, VID_COLS		; CL = current video mode cols (80 or 40), CH = 0
	MOV	AX, ES			; source and destination is video/regen RAM
	MOV	DS, AX
	MOV	AX, BP			; AL = # of rows to scroll
	SHL	CL, 1				; WORD-align bytes per full row (now 160 or 80)
	MUL	CL				; AX = size in WORDs of full rows to scroll
	XCHG	AX, BP			; AL = # rows, AH = func, BP = WORD size of rect. rows
	ADD	DX, 101H			; convert 0-based indexes to 1-based loop counters
	SAHF					; set ZF if scroll up
	MOV	AH, BH			; AH = fill attribute byte
	PUSHF					; save scroll direction flag (out of registers!)
	MOV	BX, CX			; BX = WORD size of one screen row (80 or 160)
	MOV	CL, DL			; CX = BYTE size of one rectangle row
	SUB	BX, CX			; BX = WORD offset btwn end of rect. col and start col
	SUB	BX, CX			;  on next row (subtract twice to WORD align)
	POPF					; set ZF if scroll up
	JZ	INT_10_CGA_CHECK		; jump if scroll up

;----------------------------------------------------------------------------;
; On scroll down, subtract (instead of add) the difference between the end 
; of the current rectangle and the next row start.
;
; The start address of source rectangle will also be above (instead of below)
; the destination rectangle.
;
; These offsets are then added the top/bottom of current rectangle to get the
; new rectangle coords, either above or below depending on scroll direction.
;
	NEG	BX				; BX = - WORD size offset to start of next row
	NEG	BP				; BP = - WORD size of region of rows to scroll

;----------------------------------------------------------------------------;
; If CGA, blank video during memory writes to avoid "CGA snow" effect
;
INT_10_CGA_CHECK:
	CALL	INT_10_IS_CGA80		; ZF if CGA 80, NZ if not
	PUSHF					; save flags to use same result at end
	JNZ	INT_10_6_CHECK_CLS	; jump if not mode 2 or 3 CGA 80 col text

;----------------------------------------------------------------------------;
; Blank CRTC video during memory writes to avoid "CGA snow" effect.
;
INT_10_CGA_DISABLE:
	PUSH	AX
	PUSH	DX
	MOV	DX, CGA_STAT		; CGA Status (3DAH)
INT_10_CGA_WAIT:
	IN	AL, DX			; get CRTC status register
				IF CGA_SNOW_REMOVE EQ 3
	TEST	AL, MASK VSVS OR MASK VSHS	; in HSYNC or VSYNC?
				ELSE
	TEST	AL, MASK VSVS 		; is in VSYNC?
				ENDIF
	JZ	INT_10_CGA_WAIT		; loop until it is
	MOV	DL, LOW CGA_CTRL		; CGA Control (3D8H)
	MOV	AL, 00100101B		; Mode 80x25 text, BW, disable video, blink
	OUT	DX, AL			; disable video
	POP	DX
	POP	AX

INT_10_6_CHECK_CLS:
	TEST	AL, AL			; is number of lines to scroll 0?
	JZ	INT_10_6_TXT_CLR		; if so, skip move and only clear

;----------------------------------------------------------------------------;
; Move scrolled window rectangle to new location in video memory 
;
	SUB	DH, AL			; DH = rect height - lines to scroll
	ADD	SI, BP			; SI = source row starting address
INT_10_6_TXT_MOVE_LOOP:
	MOV	CL, DL			; CX = number of columns (chars) to move
	REP	MOVSW				; copy row from [DS:SI] to [ES:DI]
	ADD	DI, BX			; move to start of next row
	ADD	SI, BX
	DEC	DH
	JNZ	INT_10_6_TXT_MOVE_LOOP	; loop through all rows
	MOV	DH, AL			; DH = remaining lines to clear

;----------------------------------------------------------------------------;
; Clear (fill with spaces) the newly cleared area
;
INT_10_6_TXT_CLR:
	MOV	AL, VID_SP			; fill blank lines with spaces
INT_10_6_TXT_CLR_LOOP:
	MOV	CL, DL			; write rect width number of blank chars
	REP	STOSW				; write attribute and space to col
	ADD	DI, BX			; move to start of next row
	DEC	DH
	JNZ	INT_10_6_TXT_CLR_LOOP	; loop through all rows

;----------------------------------------------------------------------------;
; If is CGA 80 column, re-enable the video signal
;
	POPF					; ZF if CGA/80, NZ if not
	POP	DS				; restore BDA SEG
	JNZ	INT_10_6_DONE		; jump if not CGA/80

INT_10_6_ENABLE_CGA:
	MOV	AL, VID_MODE_REG		; reload the current control register
	MOV	DX, CGA_CTRL
	OUT	DX, AL			; write to CGA Control Register

INT_10_6_DONE:
	POP	BP
	POP	SI
	POP	BX
	POP	AX
	RET

;----------------------------------------------------------------------------;
; INT 10,6/7 - Scroll up or down in graphics mode
;----------------------------------------------------------------------------;
; Input:
;	AX = memory offset of col 0 of new bottom row
;	BH = attribute to be used on blank line
;	BL = (scratch)
;	BP (high) = flags (ZF if scroll up, NZ if scroll down)
;	CH = row/Y of upper left corner of scroll window
;	CL = column/X of upper left corner of scroll window
;	DX = lower right column/X position
;	DI = original row/column parameter
;
; Perform BitBlt operation within video RAM.
;----------------------------------------------------------------------------;
INT_10_SCR_GFX PROC
	PUSH	DS
	SHL	AX, 1				; BYTE (char) align memory offset for line
	SHL	AX, 1				;  (default for 640x200)
	ADD	DX, AX
	XCHG	DX, DI			; DI = memory offset of new rect bottom
						; DX = original row/col
	ADD	DX, 101H			; use 0-based indexes for 1-based counters
	SUB	DX, CX			; DH = rect height, DL = rect width
	XCHG	AX, BP			; restore original AL / AH = func flag
	MOV	BL, AL			; BL = lines to scroll
	MOV	BP, 80			; 1 scanline = 80 bytes
	MOV	CX, 2				; CL = 2, CH = 0 (needed later for counters)
	SHL	DH, CL			; rect height * char (row) height / 2 fields
	SHL	BL, CL			; lines to scroll * char height / 2 fields
	CMP	VID_MODE, 6			; is 640x200 mode?
	JZ	INT_10_SCR_GFX_2		; jump if so

;----------------------------------------------------------------------------;
; is 320x200/4 color - adjust to 2 bits per pixel (16 bits per glyph)
;
	SHL	DI, 1				; WORD (char) align mem offset
	SHL	DL, 1				; WORD (char) align rect width
	SAHF					; set ZF if scroll up
	JZ	INT_10_SCR_GFX_RDY	; jump if scroll up

;----------------------------------------------------------------------------;
; is 320x200 AND scroll down
;
	INC	DI				; fixup start address for last pixel

INT_10_SCR_GFX_2:
	SAHF					; set ZF if scroll up
	JZ	INT_10_SCR_GFX_RDY	; jump if scroll up

;----------------------------------------------------------------------------;
; is scroll down
;
	ADD	DI, 240			; fixup bottom row of new rect.
	NEG	BP				; if scroll down, subtract offset instead

;----------------------------------------------------------------------------;
; ready to begin
;
INT_10_SCR_GFX_RDY:
	TEST	AL, AL			; is number of lines to scroll 0?
	JZ	INT_10_SCR_GFX_CLR	; if so, skip move and only clear

;----------------------------------------------------------------------------;
; Bit block transfer pixel data in video memory
;
	MOV	SI, DI			; SI = mem offset of new rectangle
	MOV	AX, BP			; AL = 1 scanline (80 if up, -80 if down)
	IMUL	BL				; AX = offset of lines to scroll * +/- 80
	ADD	SI, AX			; SI = mem offset of old rectangle
	MOV	AX, ES			; set DS to video regen segment
	MOV	DS, AX			;  for source (old) rectangle
	PUSH	BX				; save lines to clear and attribute
	SUB	DH, BL			; DH = # of lines to write
	MOV	AX, SI			; save source
	MOV	BX, DI			; save destination
INT_10_SCR_GFX_MOVE_LOOP:
	MOV	CL, DL			; # of pixels to copy
	REP	MOVSB				; copy odd field
	MOV	SI, 2000H			; vid mem offset for interlaced field
	MOV	DI, SI
	ADD	SI, AX			; add to line offset
	ADD	DI, BX
	MOV	CL, DL			; # of pixels to copy
	REP	MOVSB				; copy even field
	ADD	AX, BP			; move to next line
	ADD	BX, BP
	MOV	SI, AX			; reset source
	MOV	DI, BX			; reset dest
	DEC	DH
	JNZ	INT_10_SCR_GFX_MOVE_LOOP
	POP	BX

;----------------------------------------------------------------------------;
; Clear old window rectangle
;
	MOV	DH, BL			; # of lines to clear
INT_10_SCR_GFX_CLR:
	MOV	AL, BH			; AL = attribute/color byte to write
	MOV	SI, DI			; save destination
INT_10_SCR_GFX_CLR_LOOP:
	MOV	CL, DL			; # of pixels to clear
	REP	STOSB				; clear odd field
	MOV	DI, 2000H			; vid mem offset for interlaced field
	ADD	DI, SI
	MOV	CL, DL			; # of pixels to clear
	REP	STOSB				; clear even field
	ADD	SI, BP			; move to next line
	MOV	DI, SI			; reset dest
	DEC	DH
	JNZ	INT_10_SCR_GFX_CLR_LOOP
	POP	DS
	JMP	INT_10_6_DONE

INT_10_SCR_GFX ENDP

INT_10_6 ENDP
INT_10_7 ENDP

;----------------------------------------------------------------------------;
; INT 10,8 - Read character and attribute at cursor
;----------------------------------------------------------------------------;
; Input:
;	BH = display page
; Return:
;	AH = attribute of character (alpha modes only)
;	AL = character at cursor position
;
; http://www.techhelpmanual.com/92-cga_video_snow_and_cls_flash.html
;----------------------------------------------------------------------------;
INT_10_8 PROC
	MOV	DI, VID_MEM_SEG		; ES = video RAM segment
	MOV	ES, DI
	CALL	INT_10_GET_CUR_ADDR	; DI = video RAM offset of cursor
	MOV	AL, VID_MODE		; AL = current video mode (0-7)
	CMP	AL, 7				; is MDA mode 7?
	JNZ	INT_10_8_CHK_CGA		; if not, jump to check CGA or gfx

;----------------------------------------------------------------------------;
; Standard, fast routine
;
INT_10_8_FAST:
	MOV	AX, ES:[DI]			; just write to memory and return
	RET

INT_10_8_CHK_CGA:
	SHR	AL, 1				; Video modes: 0=40,1=80,2=low-gfx,3=hi-gfx
			IF CGA_SNOW_REMOVE GT 0
	CMP	AL, 1				; is CGA modes 2,3?
	JNE	INT_10_8_NOT_CGA		; jump if not

;----------------------------------------------------------------------------;
; CGA snow-removal routine. Wait for a blanking interval before write.
;
	PUSH	DX
	MOV	DX, CGA_STAT
	CGA_WAIT_SYNC
	MOV	AX, ES:[DI]
	STI
	POP	DX
	JMP	SHORT INT_10_8_FAST

INT_10_8_NOT_CGA:
			ENDIF

	JB	INT_10_8_FAST		; if not GFX modes 4,5,6 jump to fast text
						; fall through to graphics

;----------------------------------------------------------------------------;
; INT 10,8 - Read character and attribute at cursor in CGA graphic mode
;----------------------------------------------------------------------------;
; Input:
;	AL = 3 if high res, 2 if low-res
;	ES = video mem segment
; Return:
;	AH = 0
;	AL = character at cursor position, 0 if not found
;----------------------------------------------------------------------------;
; Thx to @Raffzahn for "clean room" specs for graphics/char routines.
;----------------------------------------------------------------------------;
INT_10_8_MODE_GFX PROC
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	SUB	SP, 8				; reserve 8 bytes for target bitmap

;----------------------------------------------------------------------------;
; Lookup page, calculate charpos and set up data segments
;
	CALL	INT_10_GFX_CHARPOS	; DI = memory offset of curr. cursor
	MOV	SI, DI			; SI = memory offset of curr. cursor
	MOV	DI, SP			; DI = start of temp space
	PUSH	ES				; DS = ES
	POP	DS
	PUSH	SS				; ES = SS
	POP	ES
	MOV	CX, 4				; loop counter for high and low res
	MOV	DX, 2000h			; CGA memory interlace field offset
	CMP	AL, 3				; is high-res graphics mode?
	JZ	INT_10_8_GFX_HIGH		; jump to handle high-res 1 bpp spacing

;----------------------------------------------------------------------------;
; Low-res - Load and pack 8 character bytes from video mem into [DS:BP]
;----------------------------------------------------------------------------;
INT_10_8_MODE_GFX_LOW:
	SHL	SI, 1				; align for two bytes/char in 320x200

INT_10_8_GFX_LOW_1:
	MOV	AX, [SI]			; AX = next two chars from video mem
	XCHG	AL, AH			; convert endian from WORD read

;----------------------------------------------------------------------------;
; Shift and OR the color bits together so that non-zero value will produce 1
;
	MOV	BX, AX			; copy bit pattern
	SHL	AX, 1				; shift low bit into high bit
	OR	BX, AX			; make high bit a 1 if either bit is 1

;----------------------------------------------------------------------------;
; Copy the only odd bits from the WORD value into a BYTE value.
;
	MOV	AH, 8				; loop through the eight 2 bpp values
INT_10_8_GFX_LOW_2:
	SHL	BX, 1				; even bit into CF
	ADC	AL, AL			; shift CF onto low order bit
	SHL	BX, 1				; discard pixel odd bit
	DEC	AH				; dec loop counter
	JNZ	INT_10_8_GFX_LOW_2
	STOSB					; save byte to local storage
	XOR	SI, DX			; toggle video field memory offset
	TEST	SI, DX			; is next field even?
	JNZ	INT_10_8_GFX_LOW_1	; jump if next field is even
	ADD	SI, 80			; if next field is odd, move to next line
	LOOP	INT_10_8_GFX_LOW_1	; loop all 8 bitmap bytes and fall through

;----------------------------------------------------------------------------;
; Do a linear search (uh, time complexity anyone?) of ROM BIOS and INT 1Fh 
; for the 8x8 1 bpp bitmap at the cursor position.
;
INT_10_8_GFX_SEARCH:
	MOV	DI, SP			; DI = char bitmap from video mem
	MOV	SI, OFFSET GFX_CHARSET	; SI = BIOS ROM table
	MOV	BX, CS			; DS = CS
	MOV	DS, BX
	XOR	AX, AX			; start codepage counter at 0
INT_10_8_GFX_SEARCH_TBL:
	MOV	BX, 128			; loop counter for each charset table
INT_10_8_GFX_SEARCH_CHR:
	PUSH	SI				; save target bitmap and ROM table offsets
	PUSH	DI
	MOV	CL, 4				; compare [CS:SI] (ROM table) to
	REPE	CMPSW				;  [ES:DI] (char bitmap from vid mem)
	POP	DI				; restart target bitmap at beginning 
	POP	SI				; ROM table always advanced by 8 
	JZ	INT_10_8_GFX_DONE		; end search if match found
	ADD	SI, 8				; next char in table
	INC	AL				; next codepage to try
	JZ	INT_10_8_GFX_DONE		; if AL > 255, char not found
	DEC	BX				; dec charset loop counter
	JNZ	INT_10_8_GFX_SEARCH_CHR	; loop until end of table set

;----------------------------------------------------------------------------;
; Search again in user charset at 0000:007C (INT 1Fh).
;
	XOR	DX, DX			; DS = IVT
	MOV	DS, DX
			ASSUME DS:_IVT
	LDS	SI, _INT_1FH		; ES:SI = user charset
			ASSUME DS:_BDA
	MOV	DX, DS			; make sure custom table has been vectored
	TEST	DX, SI			; and not the default of 0000:0000
	JNZ	INT_10_8_GFX_SEARCH_TBL	; if okay, continue search 
	XOR	AX, AX			; otherwise resturn not found (0)
INT_10_8_GFX_DONE:
	ADD	SP, 8				; restore stack pointer
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	RET

;----------------------------------------------------------------------------;
; High-res - Load 8 character bytes from video mem into [DS:BP]
;----------------------------------------------------------------------------;
INT_10_8_GFX_HIGH:
	MOVSB					; copy odd field
	DEC	SI				; undo MOVSB source inc
	XOR	SI, DX			; toggle video field memory offset
	MOVSB					; copy even field
	XOR	SI, DX			; toggle video field memory offset back
	ADD	SI, 80-1			; move to next line (undo MOVSB inc of SI)
	LOOP	INT_10_8_GFX_HIGH		; loop 8 times
	JMP	INT_10_8_GFX_SEARCH	; rejoin the search

INT_10_8_MODE_GFX ENDP

INT_10_8 ENDP

;----------------------------------------------------------------------------;
; INT 10,9 - Write character and attribute at cursor
;----------------------------------------------------------------------------;
; INT 10,A - Write character at current cursor
;----------------------------------------------------------------------------;
; Input:
;	AH = 09 or 0A
;	AL = ASCII character to write
;	BH = display page  (or mode 13h, background pixel value)
;	BL = foreground color (graphics mode only)
;	CX = count of characters to write (CX >= 1)
;
; This code is performance sensitive, so jumps are prioritizied
; and some code is duplicated to avoid jumps. For example, AH=0AH is used 
; far more frequently than 09H so it gets the fall through cases.
;----------------------------------------------------------------------------;
INT_10_9 PROC
INT_10_A PROC
	PUSH	CX
	PUSH	AX				; save AX
	MOV	DI, VID_MEM_SEG
	MOV	ES, DI			; ES = video regen memory segment
	CALL	INT_10_GET_CUR_ADDR	; DI = video RAM offset of cursor
	MOV	AL, VID_MODE		; AL = current video mode (0-7)
	CMP	AL, 7				; is MDA mode 7?
	JNZ	INT_10_CHK_CGA		; if not, jump to check CGA

;----------------------------------------------------------------------------;
; Use standard, fast routine for direct video memory writes
;
INT_10_9A_FAST:
	POP	AX				; restore AX
	CMP	AH, 9				; is function 9 (char + attribute)?
	JZ	INT_10_9_FAST		; if so, jump

;----------------------------------------------------------------------------;
; AH = 0AH: Write Character
;
INT_10_A_FAST:
	STOSB					; write char, skip attribute
	INC	DI
	LOOP	INT_10_A_FAST
	POP	CX
	RET

;----------------------------------------------------------------------------;
; AH = 09H: Write Character and Attribute
;
INT_10_9_FAST:
	MOV	AH, BL			; char attribute into high byte
	REP	STOSW				; write with attribute
	POP	CX
	RET

INT_10_CHK_CGA:
	SHR	AL, 1				; group remaining video modes
			IF CGA_SNOW_REMOVE GT 0
	CMP	AL, 1				; is CGA modes 2,3?
	JNE	INT_10_A_NOT_CGA		; jump if not

;----------------------------------------------------------------------------;
; Use slower CGA-specific snow-removal routines for memory writes during
; screen blanking.
;
INT_10_9A_CGA:
	POP	AX				; restore AX
	PUSH	BX				; save BX
	PUSH	DX
	MOV	DX, CGA_STAT
	CMP	AH, 9				; is function 9 (char + attribute)?
	JZ	INT_10_9_CGA

;----------------------------------------------------------------------------;
; AH = 0AH: Write Character (CGA Text)
;
INT_10_A_CGA:
	XCHG	AX, BX			; save AX
	CGA_WAIT_SYNC			; wait for blanking to write memory
	XCHG	AX, BX			; restore AX
	STOSB					; write char, skip attribute
	STI
	INC	DI
	LOOP	INT_10_A_CGA
INT_10_A_CGA_DONE:
	POP	DX
	POP	BX
	POP	CX
	RET

;----------------------------------------------------------------------------;
; AH = 09H: Write Character and Attribute (CGA Text)
;
INT_10_9_CGA:
	MOV	AH, BL			; char attribute into high byte
INT_10_9_CGA_LOOP:
	XCHG	AX, BX			; save AX
	CGA_WAIT_SYNC			; wait for blanking to write memory
	XCHG	AX, BX			; restore AX
	STOSW
	STI
	LOOP	INT_10_9_CGA_LOOP
	JMP	SHORT INT_10_A_CGA_DONE
INT_10_A_NOT_CGA:
			ENDIF

	JB	INT_10_9A_FAST		; is not GFX modes 4,5,6 jump to fast text
	POP	AX				; restore AX and fall through to graphics

;----------------------------------------------------------------------------;
; INT 10, 9 and A - Write character in CGA graphics mode
;----------------------------------------------------------------------------;
INT_10_9A_MODE_GFX PROC
	PUSH	AX
	PUSH	BX
	PUSH	DX
	PUSH	SI
	PUSH	DS
	MOV	BH, VID_MODE		; BH = current video mode
	CALL	INT_10_GFX_CHARPOS	; DI = memory offset of curr. cursor

;----------------------------------------------------------------------------;
; If extended ASCII, use custom table revectored at 1Fh
;
	MOV	SI, OFFSET GFX_CHARSET	; default to lower set using BIOS table
	MOV	DX, CS			;  located in CS
	MOV	DS, DX			; DS = CS
	TEST	AL, AL			; is extended (AL > 127)?
	JNS	INT_10_9A_GFX_2		; Jump if not
	AND	AL, 01111111b		; AL = low 7 bits of CP
	XOR	DX, DX			; Set DS to IVT to load DS and SI from
	MOV	DS, DX			; INT 1Fh
			ASSUME DS:_IVT
	LDS	SI, _INT_1FH		; use custom font table
			ASSUME DS:_BDA

INT_10_9A_GFX_2:
	CBW					; AH = 0
	SHL	AX, 1				; AX = char * 8
	SHL	AX, 1
	SHL	AX, 1
	ADD	SI, AX			; SI = offset in char table
	CMP	BH, 6
	JE	INT_10_9A_GFX_HIGH	; jump if high res

;----------------------------------------------------------------------------;
; Low-res (320x200) graphics modes 4-5
;----------------------------------------------------------------------------;
; Input:
;	AX = ASCII character to write * 8 bytes
;	BH = video mode
;	BL = foreground color
;	CX = number of times to repeat character
;	DS:SI = start of character offset in font bitmap table
;	ES:DI = cursor location in video RAM
;----------------------------------------------------------------------------;
; Things you must do:
;	1. Transform each BYTE of 1 bit glyph into 2 bpp color WORD
;	2. If BL has high bit set, XOR new char with current char
;	3. Write new bitmap to CGA interlaced video memory
;----------------------------------------------------------------------------;
INT_10_9A_GFX_LOW:
	MOV	DL, BL			; DL = foreground color bits
	AND	DX, 0011b			; zero extend 2 bit color

;----------------------------------------------------------------------------;
; Repeat/expand 2 color bits in DL into into DX
;
INT_10_9A_GFX_FG:
	OR	DH, DL			; copy 2 bits
	SHL	DL, 1				; move color bits to next position
	SHL	DL, 1
	JNZ	INT_10_9A_GFX_FG		; loop until DL = 0
	MOV	DL, DH			; copy to both bytes of DX

;----------------------------------------------------------------------------;
; Repeat for number of chars to write in CX to create color mask
;
	SHL	DI, 1				; align for two bytes/char in 320x200
INT_10_9A_GFX_LOW_CHAR:
	PUSH	SI				; save char glyph start offset for each loop
	PUSH	DI				; start each char at first row of vid mem

;----------------------------------------------------------------------------;
; Transform glyph bitmap to 2 bit color and move into video memory
;
	PUSH	CX				; save repeat counter
	MOV	CX, 8				; loop 8 bytes
INT_10_9A_GFX_LOW_BYTE:
	LODSB					; Load next byte

;----------------------------------------------------------------------------;
; Parallel-deposit bits of input char and transform 1 bit pixel into 2 bpp
;
	PUSH	BX
	PUSH	CX				; save bitmap counter
	XOR	BX, BX			; clear output
	MOV	CL, 8				; loop 8 bits of input char
INT_10_9A_GFX_LOW_PDEP:
	SHL	AL, 1				; CF = source pixel bit
	LAHF					; save CF
	ADC	BX, BX			; shift CF into next bit
	SAHF					; restore CF
	ADC	BX, BX			; shift CF into next bit again
	LOOP	INT_10_9A_GFX_LOW_PDEP
	XCHG	AX, BX			; AX = result
	XCHG	AL, AH			; convert endian
	POP	CX
	POP	BX
	AND	AX, DX			; combine with color mask

;----------------------------------------------------------------------------;
; In gfx mode, if BL bit 7=1 then value of BL is XOR'ed with the bg color
;
	TEST	BL, BL			; high bit set?
	JNS	INT_10_9A_GFX_LOW_WR	; jump if not
	XOR	AX, ES:[DI]			; XOR byte for current field
INT_10_9A_GFX_LOW_WR:
	MOV	ES:[DI], AX			; write 2 bytes to video memory
	XOR	DI, 2000h			; alternate video fields
	TEST	DI, 2000h			; is an even field next?
	JNZ	INT_10_9A_GFX_LOW_NEXT	; jump if even (use same offset for even)
	ADD	DI, 80			; if next is odd, move to next bitmap row
INT_10_9A_GFX_LOW_NEXT:
	LOOP	INT_10_9A_GFX_LOW_BYTE	; loop 8 glyph bytes/lines

	POP	CX				; restore repeat counter
	POP	DI
	POP	SI
	INC	DI				; move to next video mem WORD offset
	INC	DI
	LOOP	INT_10_9A_GFX_LOW_CHAR	; repeat for CX number of chars

INT_10_9A_MODE_GFX_DONE:
	POP	DS
	POP	SI
	POP	DX
	POP	BX
	POP	AX

INT_10_9A_MODE_GFX_EXIT:
	POP	CX				; restore CX and rebalance stack
	RET

;----------------------------------------------------------------------------;
; High-res (640x200) graphics mode 6
;----------------------------------------------------------------------------;
; Input:
;	AX = ASCII character to write * 8 bytes
;	BH = current video mode
;	BL = foreground color
;	CX = number of times to repeat character
;	DS:SI = start of character offset in font bitmap table
;	ES:DI = cursor location in video RAM
;----------------------------------------------------------------------------;
; Things you must do:
;	1. If BL has high bit set, XOR new char with current char
;	2. Write new bitmap to CGA interlaced video memory
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Repeat for number of chars to write in CX
;
INT_10_9A_GFX_HIGH:
	PUSH	SI				; save char glyph start offset for each loop
	PUSH	DI				; start each char at first row of vid mem

;----------------------------------------------------------------------------;
; Copy glyph bitmap to interlaced video memory
;
	MOV	BH, 4				; loop 4 words (8 bytes)
INT_10_9A_GFX_HIGH_WORD:
	LODSW					; load next two glyph rows

;----------------------------------------------------------------------------;
; In gfx mode, if BL bit 7=1 then value of BL is XOR'ed with the bg color
;
	TEST	BL, BL			; high bit set?
	JNS	INT_10_9A_GFX_HIGH_WR	; jump if not
	XOR	AL, ES:[DI]			; XOR byte on odd field
	XOR	AH, ES:[DI+2000H]		; and even field

;----------------------------------------------------------------------------;
; Write next two bytes to each field
;
INT_10_9A_GFX_HIGH_WR:
	STOSB					; write odd field in AL
	MOV	ES:[DI+2000H-1], AH	; write even field in AH
	ADD	DI, 80-1			; move to next bitmap row
	DEC	BH
	JNZ	INT_10_9A_GFX_HIGH_WORD	; loop 4 words
	POP	DI				; restore video mem cursor offset
	POP	SI				; restore start of glyph
	INC	DI				; move to next video mem BYTE offset 
	LOOP	INT_10_9A_GFX_HIGH	; repeat for CX number of chars

	JMP	INT_10_9A_MODE_GFX_DONE	; exit

;----------------------------------------------------------------------------;
; Calculate graphics memory address for current current position
;----------------------------------------------------------------------------;
; Input: DS = BDA
; Output:
;	DI = Current cursor vid mem offset
;
; Clobbers DX
;----------------------------------------------------------------------------;
INT_10_GFX_CHARPOS PROC
	MOV	DI, AX			; save original AX
	MOV	AL, BYTE PTR VID_COLS	; AL = screen mode cols (40 or 80)
	MOV	DX, VID_CURS_POS		; DH = cursor row pos, DL = column
	MUL	DH				; AX = screen cols * current row
	SHL	AX, 1				; AX = AX * 4
	SHL	AX, 1				; (8 rows / 2 fields)
	XCHG	AX, DX			; AL = current column, DX = row offset
	CBW					; AX = current column
	ADD	AX, DX			; AX = current row/column vid mem offset
	XCHG	AX, DI			; AX = original, DI = row/col vid mem offset
	RET
INT_10_GFX_CHARPOS ENDP

INT_10_9A_MODE_GFX ENDP

INT_10_A ENDP
INT_10_9 ENDP

;----------------------------------------------------------------------------;
; INT 10,B - Set color palette
;----------------------------------------------------------------------------;
; Input:
;	AH = 0B
;	BH = palette color ID
;	   = 0 to set background and border color
;	   = 1 to select 4 color palette
;	BL = color value (when BH = 0)
;	   = palette value (when BH = 1)
;----------------------------------------------------------------------------;
;	|7|6|5|4|3|2|1|0|  3D9 Color Select Register (3B9 not used)
;	 | | | | | `-------- RGB for background
;	 | | | | `--------- intensity
;	 | | | `---------- unused
;	 | | `----------- 1 = palette 1, 0=palette 0 (see below)
;	 `-------------- unused
;
;	  Palette 0 = green, red, brown
;	  Palette 1 = cyan, magenta, white
;----------------------------------------------------------------------------;
INT_10_B PROC
	PUSH	AX
	MOV	AL, VID_COLOR		; get current color byte
	TEST	BH, BH			; set BG/border or palette?
	JNZ	INT_10_B_SET_PAL		; jump if set palette
INT_10_B_SET_COL:
	AND	AL, 11100000B		; Keep current palette
	AND	BL, 00011111B		; isolate color bites
	JMP	SHORT INT_10_B_DONE
INT_10_B_SET_PAL:
	AND	AL, 11011111B		; clear palette bit
	AND	BL, 00000001B		; isolate palette selector bit
			IF CPU_TYPE	EQ CPU_V20
	ROR	BL, 3				; move low bit into bit 5
			ELSE
	ROR	BL, 1				; move low bit into bit 5
	ROR	BL, 1
	ROR	BL, 1
			ENDIF
INT_10_B_DONE:
	OR	AL, BL			; combine bytes
	MOV	VID_COLOR, AL		; save to BDA
	PUSH	DX
	MOV	DX, VID_PORT
	ADD	DL, 5				; DX = 03D9H
	OUT	DX, AL			; send to CGA Color Select Register
	POP	DX
	POP	AX
	RET
INT_10_B ENDP

;----------------------------------------------------------------------------;
; INT 10,C - Write graphics pixel at coordinate
;----------------------------------------------------------------------------;
; Input:
;	AL = color value (XOR'ED with current pixel if bit 7=1)
;	BH = page number, see VIDEO PAGES
;	CX = column number (zero based)
;	DX = row number (zero based)
;----------------------------------------------------------------------------;
INT_10_C PROC
	PUSH	AX
	PUSH	CX
	MOV	DI, VID_MEM_SEG		; ES to video memory
	MOV	ES, DI
	CALL	INT_10_GFX_PIXEL		; DI = memory offset, AH/CL mask/counter
	MOV	CH, AL			; save original AL
	AND	AL, AH			; mask only selected pixel
	SHL	AL, CL			; shift into correct bit position
	TEST	CH, CH			; is high bit of color value set?
	JS	INT_10_C_XOR		; if so, XOR byte in memory
	SHL	AH, CL			; shift mask for pixel position
	NOT	AH				; invert mask to clear current pixel
	AND	AH, ES:[DI]			; clear pixel bits
	OR	AL, AH			; replace with new pixel value
	STOSB					; write to video buffer
INT_10_C_DONE:
	POP	CX
	POP	AX
	RET
INT_10_C_XOR:
	XOR	ES:[DI], AL			; just XOR and 'XIT
	JMP	SHORT INT_10_C_DONE
INT_10_C ENDP

;----------------------------------------------------------------------------;
; INT 10,D - Read graphics pixel at coordinate
;----------------------------------------------------------------------------;
; Input:
;	BH = page number
;	CX = X / column (zero based)
;	DX = Y / row (zero based)
; Return:
;	AL = color of pixel read
;	AH clobbered
;----------------------------------------------------------------------------;
INT_10_D PROC
	PUSH	CX
	MOV	DI, VID_MEM_SEG		; ES to video memory
	MOV	ES, DI
	CALL	INT_10_GFX_PIXEL		; DI = memory offset, AH/CL mask/counter
	MOV	AL, ES:[DI]			; read packed pixel byte
	SHR	AL, CL			; shift into low order bit(s)
	AND	AL, AH			; mask only selected pixel
	POP	CX
	RET
INT_10_D ENDP

;----------------------------------------------------------------------------;
; Get Video Memory Pixel Offset and Pixel Byte Mask
;----------------------------------------------------------------------------;
; Input:
;	CX = X / column (zero based)
;	DX = Y / row (zero based)
;
; Return:
;	DI = pixel byte offset
;	AH = pixel data mask
;	CL = pixel right shift counter
;	CH = pixel index (big endian)
;
; Example of read:
;	MOV	AL, PIXEL_DAT
;	SHR	AL, CL
;	AND	AL, AH
;
; http://www.techhelpmanual.com/89-video_memory_layouts.html
;----------------------------------------------------------------------------;
INT_10_GFX_PIXEL PROC
	PUSH	BX
	PUSH	DX

;----------------------------------------------------------------------------;
; Calculate X offset
;
	MOV	DI, CX		; DI = X position (zero based)
	SHR	DI, 1
	SHR	DI, 1			; DI = DI / 4 (two bit alignment)

;----------------------------------------------------------------------------;
; Unpack pixel bit(s)
;
	MOV	AH, 0011B		; pixel mask = 0011B
	MOV	BL, AH		; index mask = 0011B (bits 0-3)
	MOV	CH, CL		; save CH = CL
	MOV	CL, 1			; ROL multiplier = 1
	CMP	VID_MODE, 6		; is 640x200 gfx mode?
	JB	NOT_HI_RES		; if low-res, skip

;----------------------------------------------------------------------------;
; Is "high res" (640x200)
;
	SHR	AH, 1			; pixel mask = 0001B
	RCL	BL, 1			; index mask = 0111B (bits 0-7)
	DEC	CX			; ROL multiplier = 0
	SHR	DI, 1			; DI = DI / 8 (one bit alignment)
NOT_HI_RES:

;----------------------------------------------------------------------------;
; Calculate right-shift counter:
; - 640x200: CL = (7 - i) * 1
; - 320x200: CL = (3 - i) * 2
;
	AND	CH, BL		; CH = packed pixel index
	SUB	BL, CH		; calculate right-shift counter
	SHL	BL, CL		; multiply by 1 (high res) or 2 (low res)
	MOV	CL, BL		; CL = shift count

;----------------------------------------------------------------------------;
; Calculate Y offset
;
; Y offset = (DX / 2) * 80 + 2000H if DX % 2 == 1
;
	SHR	DX, 1			; DX = DX / 2
	XCHG	DL, DH		; DX = DX << 4
	JNC	FIELD_EVEN		; is odd or even field?
	ADD	DI, 2000H		; odd field address offset
FIELD_EVEN:
	SHR	DX, 1
	SHR	DX, 1
	ADD	DI, DX		; DI += (DX / 2) * 16
	SHR	DX, 1
	SHR	DX, 1
	ADD	DI, DX		; DI += (DX / 2) * 64
	POP	DX
	POP	BX
	RET
INT_10_GFX_PIXEL ENDP

;----------------------------------------------------------------------------;
; INT 10,E - Write text in teletype mode
;----------------------------------------------------------------------------;
; Input:
;	AH = 0E
;	AL = ASCII character to write
;	BH = page number (text modes) - override it with BDA value though
;	BL = foreground pixel color (graphics modes)
;
; Output:
;	Character to console
;	All registers preserved
;----------------------------------------------------------------------------;
; Things you must do:
;	1. Get video page from BDA - ignore what was passed in BH (why?)
;	2. Get cursor location (INT 10,3) and keep it handy.
;	3. Check for the four special control codes: BELL(7), BS(8), LF(A), CR(D)
;		- BELL: beep and exit
;		- Backspace: if cursor column is 0, exit else DEC col and go to 6
;		- CR: set cursor to column 0 and go to step 6
;		- LF: Increment row and go to step 5 to check if scroll is needed
;	4. Write the char to the current position (INT 10,A)
;	5. If new row > last row, scroll up 1 row (INT 10,8).
;	6. Update cursor position (INT 10,6)
;
;----------------------------------------------------------------------------;
INT_10_E PROC
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	CALL	INT_10_GET_PAGE	; BH = video page for CGA text, 0 for GFX/MDA
	CALL	INT_10_3		; Get cursor position: DH = row, DL = column
	CMP	AL, CR		; is maybe a control code?
	JBE	INT_10_E_CTRL	; if so, jump to handle it

;----------------------------------------------------------------------------;
; Handle a regular char
;
INT_10_E_CHAR:
	MOV	CX, 1				; repeat only once
	CALL	INT_10_A			; write char in AL at current row/col

;----------------------------------------------------------------------------;
; Handle line wrap
;
	MOV	CL, BYTE PTR VID_COLS	; get screen cols
	DEC	CX				; fix 0 index
	CMP	DL, CL			; reached end of screen cols?
	JB	NEXT_COL			; jump if not
	MOV	DL, -1			; else move to first col and next row 
NEXT_COL:
	INC	DX				; move to next column (and maybe row)

;----------------------------------------------------------------------------;
; Scroll if necessary
;
INT_10_E_SCROLL:
	CMP	DH, VID_DEF_ROWS		; moved past last row?
	JBE	INT_10_E_CURS		; if not, no scroll necessary
	XOR	AH, AH			; attribute = 0 if gfx mode
	DEC	DH				; undo row scroll
	CALL	INT_10_IS_TXT		; ZF = 1 if CGA/MDA Text, ZF = 0 if gfx
	JNZ	INT_10_E_SCROLL_UP	; jump if graphics
	CALL	INT_10_8			; Read character: AH = attribute, AL = char

;----------------------------------------------------------------------------;
; Scroll up one line
;
INT_10_E_SCROLL_UP:
	PUSH	BX				; save video page (BH)
	XCHG	AX, BX			; BH = attribute
	MOV	AX, 0601H			; AH = 06H Scroll Window Up, AL = 1 line
	XOR	CX, CX			; scroll top left: CH = row 0, CL = col 0
	PUSH	DX				; save cursor bottom
	MOV	DL, BYTE PTR VID_COLS	; DL = right-most column
	MOV	DH, VID_DEF_ROWS		; DH = bottom row (always 24)
	DEC	DX				; fixup 0-indexed column
	CLD
	CALL	INT_10_6			; INT 10H, 06H Scroll Window Up
	POP	DX				; restore cursor bottom
	POP	BX				; restore video page (BH)

;----------------------------------------------------------------------------;
; Set new cursor position
;
INT_10_E_CURS:
	CALL	INT_10_2			; set cursor pos: BH = page, row = DH, col = DL

INT_10_E_DONE:
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

;----------------------------------------------------------------------------;
; Handle control codes
;
INT_10_E_CTRL:
	JZ	INT_10_E_CR			; ZF = CR (from above)
	CMP	AL, LF			; is an LF?
	JZ	INT_10_E_LF
	CMP	AL, BS			; is a backspace?
	JZ	INT_10_E_BS
	CMP	AL, BELL			; Isabelle?
	JNZ	INT_10_E_CHAR		; otherwise, handle as a normal char
INT_10_E_BELL:
	POP	DX				; clear stack, beep and exit
	POP	CX
	POP	BX
	POP	AX
	JMP	BEEP				; standard BEEP and RET
INT_10_E_CR:
	XOR	DL, DL			; move to column 0
	JMP	INT_10_E_CURS		; update cursor
INT_10_E_LF:
	INC	DH				; move to next row
	JMP	INT_10_E_SCROLL		; maybe scroll
INT_10_E_BS:
	TEST	DL, DL			; is first column? (can't backspace further)
	JZ	INT_10_E_DONE		; if so, do nothing and exit
	DEC	DX				; back space one column
	JMP	INT_10_E_SCROLL		; maybe scroll

INT_10_E ENDP

;----------------------------------------------------------------------------;
; INT 10,F - Get current video state
;----------------------------------------------------------------------------;
; Input:
;	AH = 0F
; Return:
;	AH = number of screen columns
;	AL = mode currently set
;	BH = current display page
;----------------------------------------------------------------------------;
INT_10_F PROC
	MOV	AX, WORD PTR VID_MODE
	MOV	BH, VID_PAGE
	RET
INT_10_F ENDP

;----------------------------------------------------------------------------;
; Get video memory offset for current cursor position
;----------------------------------------------------------------------------;
; Input:
;	BH = current video page
; Return:
;	DI = memory offset of current cursor in memory
;----------------------------------------------------------------------------;
INT_10_GET_CUR_ADDR PROC
	PUSH	AX
	PUSH	DX
	MOV	AL, BH			; AL = display page
	CBW					; AX = page number
	XCHG	AX, DI			; DI = page number
	MOV	AX, VID_BUF_SZ		; AX = VID_BUF_SZ
	MUL	DI				; AX = page size * page (base offset)
	SHL	DI, 1				; word align index
	MOV	DX, VID_CURS_POS[DI]	; DX = cursor position on page
	XCHG	AX, DI			; DI = page base offset
	MOV	AL, BYTE PTR VID_COLS
	MUL	DH				; AX = screen cols * current row
	XCHG	AX, DX			; DX = rows offset, AL = current col
	CBW					; AX = current col
	ADD	AX, DX			; AX = page relative cursor offset
	SHL	AX, 1				; word align
	ADD	DI, AX			; DI = memory offset of cursor
	POP	DX
	POP	AX
	RET
INT_10_GET_CUR_ADDR ENDP

;----------------------------------------------------------------------------;
; Get correct VID_PAGE for current video mode
;----------------------------------------------------------------------------;
; Return:
;	ZF = 0 and BH = 0 if MDA/CGA GFX
;  	ZF = 1 and BH = VID_PAGE if CGA text
;----------------------------------------------------------------------------;
INT_10_GET_PAGE PROC
	XOR	BH, BH			; BH = 0
	TEST	VID_MODE, 0100B		; is >= 4?
	JNZ	INT_10_GET_PAGE_DONE	; jump if not MDA or GFX
	MOV	BH, VID_PAGE		; otherwise BH = VID_PAGE
INT_10_GET_PAGE_DONE:
	RET
INT_10_GET_PAGE ENDP

;----------------------------------------------------------------------------;
; 6845 CRT mode control register values
;----------------------------------------------------------------------------;
; CGA:
;	|7|6|5|4|3|2|1|0|  3D8H Mode Select Register
;	     | | | | | `---- 1 = 80x25 text, 0 = 40x25 text
;	     | | | | `----- 1 = 320x200 graphics, 0 = text (unused on MDA)
;	     | | | `------ 1 = B/W, 0 = color (unused on MDA)
;	     | | `------- 1 = enable video signal
;	     | `-------- 1 = 640x200 B/W graphics (unused on MDA)
;	     `--------- 1 = blink, 0 = no blink
; MDA:
;	|7|6|5|4|3|2|1|0|  3B8 CRT Control Port
;	     | | | | | `---- 1 = 80x25 text
;	     | | | `------- unused
;	     | | `-------- 1 = enable video signal
;	     | `--------- unused
;	     `---------- 1 = blinking on
;
; source: https://stanislavs.org/helppc/6845.html
;----------------------------------------------------------------------------;
CRT_MODE	DB	101100B	; 00: 40x25 B/W text (CGA)
		DB	101000B	; 01: 40x25 16 color text (CGA)
		DB 	101101B	; 02: 80x25 16 shades of gray text (CGA)
		DB	101001B	; 03: 80x25 16 color text (CGA)
		DB	101010B	; 04: 320x200 4 color graphics (CGA)
		DB	101110B	; 05: 320x200 4 color graphics (CGA)
		DB	011110B	; 06: 640x200 B/W graphics (CGA)
		DB	101001B	; 07: 80x25 Monochrome text (MDA, HERC)

INT_10 ENDP

;-------------------------------------------------------------------------
; POST_FD_TEST_DRIVE: Reset, Recalibrate and Seek test a floppy drive at POST
;-------------------------------------------------------------------------
; Input:
;	DL = drive # to test (0 = A:, 1 = B:)
; Output:
;	CF if error
; Size: 49 bytes
;-------------------------------------------------------------------------
POST_FD_TEST_DRIVE PROC
	PUSH	AX
	PUSH	CX
	PUSH	SI
	CALL	FDC_RECAL				; Motor on, recal, DL = drive
	JC	FDC_TEST_DRIVE_DONE		; exit if error
	JWB	FDC_TEST_DRIVE_DONE		; skip seek tests on warm boot
	IO_DELAY_LONG				; just because?
	MOV	SI, OFFSET FDC_TEST_DRIVE_CYL
	CALL	FDC_MOTOR_ON			; reset motor run count (clobbers CX)
FDC_TEST_DRIVE_SEEK:
	LODS	BYTE PTR CS:[SI]
	TEST	AL, AL				; end of pattern (-1)?
	JS	FDC_TEST_DRIVE_DONE		; if so, done
	MOV	CH, AL
	CALL	FDC_SEEK				; CH = track, DL = drive
	JNC	FDC_TEST_DRIVE_SEEK
	IO_DELAY_LONG				; just because?
FDC_TEST_DRIVE_DONE:
	POP	SI
	POP	CX
	POP	AX
	RET

;----------------------------------------------------------------------------;
; Track seek pattern for POST seek test
;
FDC_TEST_DRIVE_CYL	DB	0, 38, 2, 20, 0, -1	; tracks (-1 is end)

POST_FD_TEST_DRIVE ENDP

POST_COL PROC
;----------------------------------------------------------------------------;
; Write POST column label and start separator 
;----------------------------------------------------------------------------;
; - Start new line
; - display column name in color 1
; - display left separator in color 1
; - set color for inner text to be color 2
;----------------------------------------------------------------------------;
; Input:
; - SI: column name string
; - BL: inner text color/attribute
; - CX: inner text color length
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Handle 40 column mode - move to next line and fall through to col 1
;
POST_START_COL_2_40:
	CALL	CRLF				; move to next line
	POP	AX				; rebalance stack

POST_START_COL_1 PROC
	PUSH	AX
	MOV	AL, POST_COL_W		; column 1 tab width
POST_START_COL_START:
	PUSH	BX				; save inner text color
	MOV	AH, BL			; save text color
	MOV	CX, POST_COL_VT		; set attribute on next CX # of chars
	MOV	BX, LOW POST_CLR_TXT	; set outer text color
	CALL	OUT_SZ_ATTR			; write SI string with attribute
	CALL	MOVE_COL			; move cursor to separator column
	MOV	SI, OFFSET POST_LSEP	; write separator string with 
	CALL	OUT_SZ			;  existing attribute
	MOV	BL, AH
	CALL	MDA_COLOR_FIX		; strip underline and blink on MDA
	MOV	AX, 900H OR ' '		; AH = write char w/attr, AL = space 
	MOV	CL, POST_TAB_COL_I	; CX = repeat times 
	INT	10H 
	POP	BX				; BL = attribute for next CX chars
	POP	AX
	RET
POST_START_COL_1 ENDP

;----------------------------------------------------------------------------;
; Same as POST_START_COL_1 except starts at column 2
;----------------------------------------------------------------------------;
POST_START_COL_2 PROC
			ASSUME DS:_BDA
	PUSH	AX
	MOV	AH, 0FH			; get video mode
	INT	10H				; AL = video mode
	CMP	AL, 1				; is 40 column mode?
	JLE	POST_START_COL_2_40
	MOV	AL, POST_TAB_COL		; move to start of column 2
	CALL	MOVE_COL
	MOV	AL, POST_TAB_COL+POST_COL_W	; set abs. position for column 2 tab
	JMP	POST_START_COL_START
POST_START_COL_2 ENDP

;----------------------------------------------------------------------------;
; Write POST column end separator 
;----------------------------------------------------------------------------;
; Display right separator in color POST_CLR_TXT
;----------------------------------------------------------------------------;
POST_END_COL PROC NEAR
	MOV	SI, OFFSET POST_RSEP
POST_END_COL_STR PROC NEAR
	MOV	CX, 2
	MOV	BX, LOW POST_CLR_TXT
	JMP	SHORT OUT_SZ_ATTR			; CALL and RET
POST_END_COL_STR ENDP
POST_END_COL ENDP

;----------------------------------------------------------------------------;
; Same as POST_END_COL and displays a CRLF
;----------------------------------------------------------------------------;
POST_END_COL_NL PROC
	CALL	POST_END_COL
	JMP	SHORT CRLF
POST_END_COL_NL ENDP

POST_COL ENDP

;----------------------------------------------------------------------------;
; Display a zero-terminated string in BIOS at CS:[SI] with ending NL
;----------------------------------------------------------------------------;
; Input: CS:SI = String
;----------------------------------------------------------------------------;
OUTLN_SZ PROC
	CALL	OUT_SZ			; write original string in SI
						; fall through to CRLF

;----------------------------------------------------------------------------;
; Write a CRLF string to console
;----------------------------------------------------------------------------;
CRLF PROC
	PRINT_SZ NL_Z, 1
	RET
CRLF ENDP

OUTLN_SZ ENDP

;----------------------------------------------------------------------------;
; Display a zero-terminated string in BIOS at CS:[SI]
;----------------------------------------------------------------------------;
; Input: CS:SI = String
;----------------------------------------------------------------------------;
OUT_SZ PROC
	PUSH	AX
	MOV	AH, 0EH			; TTY output
OUT_SZ_LOOP:
	LODS	BYTE PTR CS:[SI]		; AL = CS:[SI++]
	TEST	AL, AL			; is zero terminator?
	JZ	OUT_SZ_DONE			; if so, exit
	INT	10H
	JMP	SHORT OUT_SZ_LOOP
OUT_SZ_DONE:
	POP	AX
	RET

;----------------------------------------------------------------------------;
; Write a zero-terminated string to console with attributes, no cursor move
;----------------------------------------------------------------------------;
; Sets attribute in BL for the next CX number of characters, past end of string.
;
; Input: CS:SI = String, CX = length, BL = attribute, BH = video page
; Output: SI = end of string
;----------------------------------------------------------------------------;
OUT_SZ_ATTR PROC
	PUSH	AX
	MOV	AX, 900H OR ' '
	INT	10H
	POP	AX
	JMP	SHORT OUT_SZ
OUT_SZ_ATTR ENDP

OUT_SZ ENDP

;----------------------------------------------------------------------------;
; Walking Bit/March I/O port register test
;----------------------------------------------------------------------------;
; Input:
;	DX = starting port
;	BH = number of sequential ports to test
; Output:
;	NZ if failed
;	CX = 0 if success
;
; Adapted from:
; https://barrgroup.com/embedded-systems/how-to/memory-test-suite-c
; https://www.edaboard.com/threads/walking-1-0-test-for-memory-bist.241278/
;
; Size: 48 bytes
; Clobbers AX, BX, CX, DX, DI
;----------------------------------------------------------------------------;
WB_TEST PROC
	MOV	AH, 1				; start with low order bit
	XOR	CX, CX			; clear counter
	MOV	DI, DX			; save starting port

;----------------------------------------------------------------------------;
; Write a single 1 bit to a different position in each register
;
WB_WRITE_1:
	MOV	CL, BH			; register counter
	MOV	DX, DI 			; start at first register
	MOV	AL, AH			; AL = starting bit to write
WB_WRITE_LOOP:
	OUT	DX, AL			; write to low byte
	IO_DELAY_SHORT
	OUT	DX, AL			; write to high byte
	INC	DX				; next register/port
	ROL	AL, 1				; walk bit to next position
	LOOP	WB_WRITE_LOOP

;----------------------------------------------------------------------------;
; Read back bit pattern from each register
;
	MOV	CL, BH			; register counter
	MOV	DX, DI 			; start at first register
	MOV	BL, AH			; BL = starting bit to compare
WB_READ_LOOP:
	IN	AL, DX			; read low byte
	CMP	AL, BL			; compare to correct bit
	JNZ	WB_TEST_DONE		; jump if not okay
WB_LOW_CHECK_OK:
	IN	AL, DX			; read high byte
	CMP	AL, BL			; compare to correct bit
	JNZ	WB_TEST_DONE		; jump if not okay
	INC	DX				; next register/port
	ROL	BL, 1				; rotate for next register/bit
	LOOP	WB_READ_LOOP		; loop all eight registers
	SHL	AH, 1				; rotate to next starting bit
	JNZ	WB_WRITE_1			; loop until AH = 0
WB_TEST_DONE:
	RET
WB_TEST ENDP

;----------------------------------------------------------------------------;
; Check if AL is alpha char [A-Za-z]
;----------------------------------------------------------------------------;
; Input:
;	AL = char 'A'-'Z' or 'a'-'z'
; Output:
;	CF = 0 (NC) if alpha, CF = 1 (CY) if not alpha
; Size: 12 bytes
;----------------------------------------------------------------------------;
IS_ALPHA PROC
	PUSH	AX
	OR	AL, 'a'-'A'			; lowercase it for comparison
	CMP	AL, 'a'			; is less than 'a'?
	JB	IS_ALPHA_DONE		; CF if not alpha
	CMP	AL, 'z'+1			; is greater than 'z'?
	CMC					; CF if not alpha
IS_ALPHA_DONE:
	POP	AX
	RET
IS_ALPHA ENDP

;
; 193 bytes here
;
BYTES_HERE	INT_12

;----------------------------------------------------------------------------;
; INT 12H - Memory Size Determination
;----------------------------------------------------------------------------;
; Return:
;	AX = number of contiguous 1k memory blocks found at startup
;----------------------------------------------------------------------------;
		ORG 0F841H
INT_12 PROC
		ASSUME DS:_BDA
	STI 							; Interrupts on
	PUSH	DS 						; save DS
	MOV	AX, SEG _BDA
	MOV	DS, AX 					; DS = BDA
	MOV	AX, MEM_SZ_KB 				; AX = DS:[MEM_SZ_KB]
	POP	DS
	IRET
INT_12 ENDP

;----------------------------------------------------------------------------;
; INT 11H - BIOS Equipment Determination / BIOS Equipment Flags
;----------------------------------------------------------------------------;
; Return:
;	AX = data stored at BIOS Data Area location 0040:0010
;----------------------------------------------------------------------------;
		ORG 0F84DH
INT_11 PROC
		ASSUME DS:_BDA
	STI 							; Interrupts on
	PUSH	DS 						; save DS
	MOV	AX, SEG _BDA
	MOV	DS, AX 					; DS = BDA
	MOV	AX, EQUIP_FLAGS
	POP	DS
	IRET
INT_11 ENDP

;----------------------------------------------------------------------------;
; INT 15 - System BIOS Services / Cassette (not supported)
;----------------------------------------------------------------------------;
; Unsupported:
;	INT 15,0  Turn cassette motor on
;	INT 15,1  Turn cassette motor off
;	INT 15,2  Read blocks from cassette
;	INT 15,3  Write blocks to cassette
;
; Return:
;	CF = 1, AH = 86H (no cassette present)
;
; Docs are conflicting here for what to return:
; https://stanislavs.org/helppc/int_15.html
; http://www.ctyme.com/intr/int-15.htm
; http://www.techhelpmanual.com/212-int_15h__at_extended_services___apm.html
;----------------------------------------------------------------------------;
		ORG 0F859H
INT_15 PROC
	STI					; return with interrupts enabled
	STC 					; CF set if function not supported
	MOV	AH, 86H 			; always return no cassette present
	RETF	2				; return from INT with CF flag
INT_15 ENDP

;----------------------------------------------------------------------------;
; INT 18 - Unbootable IPL
;----------------------------------------------------------------------------;
; Display a disk boot failure message and wait for a key to cold reboot.
;
; This may be re-vectored to ROM BASIC, if present.
;
; Size: 18 bytes
;----------------------------------------------------------------------------;
INT_18 PROC
	PRINT_SZ BOOT_FAIL			; print boot failure string
	XOR	AX, AX				; AH = 0 (wait for key)
	MOV	DS, AX				; DS = 0000
			ASSUME DS:_BDA_ABS
	MOV	WARM_FLAG_ABS, AX			; do a cold boot
	INT	16H					; wait for key press
	JMP	POWER_ON				; reboot
INT_18 ENDP

POST_UI PROC

;----------------------------------------------------------------------------;
; Display system hardware config
;----------------------------------------------------------------------------;
; Input:
;	DS = BDA (0040)
;
; Clobs AX, BX, CX, SI
; Size: 133 bytes
;----------------------------------------------------------------------------;
POST_SYS_CONFIG PROC
		ASSUME DS:_BDA

			IF POST_VIDEO_TYPE EQ 1
	CALL	POST_SYS_VIDEO
			ENDIF

;----------------------------------------------------------------------------;
; Display CPU type
;
	POST_COL_1	POST_CPU, POST_CLR_VAL1	; display "CPU" left column
	MOV	SI, OFFSET POST_V20		; default to V20
CPU_CHECK_TYPE_2:
	TEST_GFLAG  V20				; ZF = 0 if V20, ZF = 1 if 8088
	JNZ	CPU_CHECK_TYPE_2_DONE		; jump if V20
	MOV	SI, OFFSET POST_8088		; if not, is 8088
CPU_CHECK_TYPE_2_DONE:
	CALL	OUT_SZ				; write CPU type
	POST_COL_END				; end first column

;----------------------------------------------------------------------------;
; Display FPU/math co-processor
;
FPU_CHECK:
	POST_COL_2	POST_FPU, POST_CLR_VAL1
	MOV	SI, OFFSET POST_NONE		; default to 'None'
	TEST_EFLAG FPU				; was FPU detected?
	JZ	FPU_DISP_DONE			; jump to output if no FPU
	MOV	SI, OFFSET POST_8087
FPU_DISP_DONE:
	CALL	OUT_SZ				; display string
	POST_COL_END_NL				; end second column, move to NL

;----------------------------------------------------------------------------;
; Display LPT ports
;
	POST_COL_1	POST_LPT, POST_CLR_VAL2
	GET_EFLAG LPT				; AX = number of LPT ports
	XCHG	AX, CX				; CX = number of ports
	MOV	SI, OFFSET LPT_ADDR
	CALL	SHOW_PORT_COUNT

;----------------------------------------------------------------------------;
; Display COM ports
;
	POST_COL_2	POST_COM, POST_CLR_VAL2
	GET_EFLAG COM				; AX = number of COM ports
	XCHG	AX, CX				; CX = number of ports
	MOV	SI, OFFSET COM_ADDR

;----------------------------------------------------------------------------;
; Display I/O addresses of COM or LPT ports on POST
;----------------------------------------------------------------------------;
; Input:
;	SI = WORD array of ports
;	CX = number of ports to show
;----------------------------------------------------------------------------;
SHOW_PORT_COUNT PROC
	JCXZ	PORT_COUNT_NONE			; if no ports, display "None"
PORT_COUNT_LOOP:
	LODSW	
	CALL	WORD_HEX				; display I/O address in hex
	CALL	SPACE					; separate ports with space
	LOOP	PORT_COUNT_LOOP
	MOV	SI, OFFSET POST_RSEP[1]		; skip leading space in right sep.
	JMP	NEAR PTR POST_END_COL_STR	; display end with sep. in SI and RET
PORT_COUNT_NONE:
	PRINT_SZ	POST_NONE			; display "None"
	JMP	NEAR PTR POST_END_COL		; display end sep and RET
SHOW_PORT_COUNT ENDP

POST_SYS_CONFIG ENDP

;----------------------------------------------------------------------------;
; Display Hard Drive Parameters
;----------------------------------------------------------------------------;
; Display info for POST in drive DL
;
; Input:
;	DL = drive #
; Output:
;	AH = status
;
; AL clobbered
;
; Size: 105 bytes
;----------------------------------------------------------------------------;
SHOW_DISK_PARAMS PROC
	PUSH	BX					; call preserve BX and CX
	PUSH	CX
	PUSH	DX					; save drive ID
	PUSH	DX					; save drive ID again
	CALL	GET_DISK_PARAMS			; AL=heads, BX=cyl, CL=sec, DL=drive
	POP	DX					; don't need drive count here
	PUSH	AX					; save return status in AH
	JC	SHOW_DISK_PARAMS_DONE		; exit if error getting drive

	SET_SZ_ATTR POST_CLR_TXT, 1, 1	; set next char to be text color
	XCHG	AX, DX				; AL = drive ID, DX = # of heads

;----------------------------------------------------------------------------;
; Display Drive letter
;
	AND	AL, 0011B				; only drives 0-3
	ADD	AL, 'C'				; convert to drive letter
	CALL	OUT_CHAR
	PUSH	CX					; save sectors/track
	PUSH	DX					; save heads

;----------------------------------------------------------------------------;
; Display HD size: MiB = C*H*S*512/1024/1024 = C*H*S/2048
;
	XCHG	AX, DX				; AX = # of heads
	MUL	CL					; AX = heads * sectors
	MUL	BX					; DX:AX = heads * sectors * cyl
	MOV	CX, 2048				; AX = DX:AX / 2048
	DIV	CX					; (size in MB)
	POST_COL_1	POST_HD, POST_CLR_VAL1, 1
	CALL	OUT_DECU				; print size in MB

;----------------------------------------------------------------------------;
; Display HD geometry
;
	PRINT_SZ POST_MB				; 'MB ('
	XCHG	AX, BX				; AX = cylinders, BX = size in MB
	CALL	OUT_DECU				; print # cylinders
	CALL	SPACE
	POP	AX					; AX = heads
	CALL	OUT_DECU				; print # heads
	CALL	SPACE
	POP	AX					; AX = sectors/track
	CALL	OUT_DECU				; print sec/track
	MOV	AL, ')'				; ')'
	CALL	OUT_CHAR
	POST_COL_END_NL

SHOW_DISK_PARAMS_DONE:
	POP	AX					; restore return status
	POP	DX
	POP	CX
	POP	BX
	RET
SHOW_DISK_PARAMS ENDP

POST_UI ENDP

;----------------------------------------------------------------------------;
; Delay using PIT counter increments of 125 ms
;----------------------------------------------------------------------------;
; Input:
;	AL = wait in 125 ms increments
;
; AX clobbered
; Size: 53 bytes
;----------------------------------------------------------------------------;
IO_WAIT_MS_125 PROC
	MOV	AH, 125
	MUL	AH				; AX = wait in 1 ms

;----------------------------------------------------------------------------;
; Delay using PIT counter increments of 1 ms
;----------------------------------------------------------------------------;
; - Calculate the total number of PIT ticks necessary (where 1,193,000 = 1s)
; - Latch the PIT and draw down the countdown total on each read.
; - Exit when countdown underflows.
;
; Note: Mode 3 (Square Wave) decements the readable counter by 2, so the
; effective frequency of the counter is actually 2,386,360 Hz.
;
; Input:
;	AX = wait in number of ms (clobbered)
;
; Based on contribution by @Raffzahn (under CC BY-SA 4.0):
; https://retrocomputing.stackexchange.com/a/24874/21323
;
; https://stanislavs.org/helppc/8253.html
;----------------------------------------------------------------------------;
IO_DELAY_MS PROC
	PUSH	BX
	PUSH	CX
	PUSH	DX
	XCHG	AX, BX			; BX = wait ms
	MOV	AX, 1193 * 2		; 1,193,180 / 1000 ms * 2 = 2,386 ticks/ms
	MUL	BX				; DX:AX = countdown of PIT ticks to wait
	XCHG	AX, BX			; DX:BX = countdown ticks
	CALL	IO_WAIT_LATCH		; AX = start read
	MOV	CX, AX			; CX = last read
IO_WAIT_MS_LOOP:
	CALL	IO_WAIT_LATCH		; AX = current counter reading
	SUB	CX, AX			; CX = # of ticks elapsed since last reading
	SUB	BX, CX			; subtract change in ticks from countdown
	MOV	CX, AX			; CX = save the last read
	SBB	DX, 0				; borrow out of high word (if necessary)
	JNC	IO_WAIT_MS_LOOP		; loop while countdown >= 0
	POP	DX
	POP	CX
	POP	BX
IO_WAIT_MS_DONE:
	RET
IO_WAIT_LATCH:
	MOV	AL, 0				; Latch Counter 0 command
	PUSHF					; save current IF
	CLI					; disable interrupts
	OUT	PIT_CTRL, AL		; Write command to CTC
	IN	AL, PIT_CH0			; Read low byte of Counter 0 latch
	MOV	AH, AL			; Save it
	IN	AL, PIT_CH0			; Read high byte of Counter 0 latch
	POPF					; restore IF state
	XCHG	AL, AH			; convert endian
	RET
IO_DELAY_MS ENDP
IO_WAIT_MS_125 ENDP

;----------------------------------------------------------------------------;
; Turn on speaker at given tone
;----------------------------------------------------------------------------;
; Input:
; 	AX = TONE
;
; http://www.cs.binghamton.edu/~reckert/220/8254_timer.html
;
; Clobbers BX
; Cannot use stack since this could be called before it is working.
;----------------------------------------------------------------------------;
BEEP_ON_P PROC
	XCHG	AX, BX			; save tone
	MOV	AL, 10110110B		; Select Timer 2, LE, Mode 3 (square), Binary
	OUT	PIT_CTRL, AL		; (10 11 011 0) Send to PIT control word (43H)
	XCHG	AX, BX			; restore tone
	OUT	PIT_CH2, AL			; send low byte to timer
	MOV	AL, AH 			; select high byte
	OUT	PIT_CH2, AL			; send high byte to timer
	IN	AL, PPI_B			; read current PPI port B status
	OR	AL, 00000011B 		; turn on speaker bits
	OUT	PPI_B, AL			; write back to port B
	RET
BEEP_ON_P ENDP

;----------------------------------------------------------------------------;
; Turn off speaker
;
; Clobbers AX
;----------------------------------------------------------------------------;
BEEP_OFF_P PROC
	IN	AL, PPI_B			; read current PPI port B status
	AND	AL, 11111100B		; turn off speaker bits
	OUT	PPI_B, AL			; write back to port B
	RET
BEEP_OFF_P ENDP

;----------------------------------------------------------------------------;
; Make a beepin' beep
;----------------------------------------------------------------------------;
; Play a (correctly pitched) A6 for 250ms
;----------------------------------------------------------------------------;
BEEP PROC
	PUSH	AX
	BEEP_ON
	MOV	AX, 250			; 1/4 second pause
	CALL	IO_DELAY_MS
	BEEP_OFF
	POP	AX
	RET
BEEP ENDP

;----------------------------------------------------------------------------;
; Two very short beeps
; Size: 27 bytes
;----------------------------------------------------------------------------;
MEEPMEEP PROC
	CALL MEEP

;----------------------------------------------------------------------------;
; One very short beep
;----------------------------------------------------------------------------;
MEEP PROC
	PUSH	AX
	PUSH	CX
	BEEP_ON
	MOV	CH, 20H
	IO_DELAY				; delay while beeping
	BEEP_OFF
	MOV	CH, 20H
	IO_DELAY				; delay between beeps
	POP	CX
	POP	AX
	RET
MEEP ENDP
MEEPMEEP ENDP

;----------------------------------------------------------------------------;
; Repeats LONG_BEEPs then SHORT_BEEPs indefinetly
;----------------------------------------------------------------------------;
; Input:
;	BL low nibble = long beeps
;	BL high nibble = short beeps
;
; Note: must use LOOP for beep since BEEP could occur if PIT is not working
; Note 2: cannot use stack since HALT_BEEP could occur before stack
;
; Size: 68 bytes
;----------------------------------------------------------------------------;
HALT_BEEP PROC NEAR
	MOV	DX, CS 				; SS to CS
	MOV	SS, DX				; for CALL_NS
	XCHG	AX, BX				; beep pattern to AL
	DB	0D4H, 10H				; AAM 10H ; split nibbles
	XCHG	AX, BP				; BH = short beeps, BL = long beeps
HALT_BEEP_START:
	MOV	DX, BP 				; get original beep pattern
HLT_LONG_BEEP_LOOP: 				; long beeps
	MOV	AX, BEEP_ERR_LOW			; low C5
	CALL_NS BEEP_ON_P				; turn on speaker / beep
	IO_DELAY_LONG				; pause between beeps
	CALL_NS BEEP_OFF_P
	IO_DELAY					; pause between beeps
	DEC	DL
	JNZ	HLT_LONG_BEEP_LOOP
HLT_SHORT_BEEP_LOOP:
	MOV	AX, BEEP_ERR_HIGH			; high F5
	CALL_NS BEEP_ON_P
	MOV	CH, 100H * 1/4			; beep on 25%
	IO_DELAY
	CALL_NS BEEP_OFF_P
	MOV	CH, 100H * 3/4			; beep off 75%
	IO_DELAY
	DEC	DH
	JNZ	HLT_SHORT_BEEP_LOOP
	JMP	SHORT HALT_BEEP_START		; beep forever
HALT_BEEP ENDP

;----------------------------------------------------------------------------;
; Write DWORD BX:AX as HEX to console
;----------------------------------------------------------------------------;
; Input: BX:AX - 32 bit value to write
; WORDS are separated by a colon ex: 1234:ABCD
;
; AX clobbered
;----------------------------------------------------------------------------;
DWORD_HEX PROC
	PUSH	AX 				; save AX
	MOV	AX, BX
	CALL	WORD_HEX 			; write AX to console as HEX
	MOV	AL, ':'
	CALL	OUT_CHAR			; Write char in AL to console
	POP	AX 				; restore AX

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
			IF CPU_TYPE	EQ CPU_V20
	DB	0FH, 28H, 0C0H		; ROL4 AL ; swap nibbles (V20 only)
			ELSE
	SHR	AL, 1				; move high nibble to low nibble
	SHR	AL, 1				; move high nibble to low nibble
	SHR	AL, 1				; move high nibble to low nibble
	SHR	AL, 1				; move high nibble to low nibble
			ENDIF
	CALL	NIB_HEX 			; write low nibble of AL as HEX to console
	POP	AX 				; restore AL

;--------------------------------------------------------------------------
; Write low nibble of AL as HEX to console
;--------------------------------------------------------------------------
NIB_HEX PROC
	AND	AL, 1111B 			; isolate low nibble
	CMP	AL, 0AH 			; if < 0Ah, CF=1 and setup a -1 for ASCII
						;  adjust since 'A'-'9' is 7 (not 6)
	SBB	AL, -('0'+66H+1) 		; BCD bias for ASCII (30h + 66h + CF)
						;  AF = AL < 0Ah, CF = 1
						;  if > 9, high_nibble = 0Ah
						;  if <=9, high_nibble = 09h
	DAS					; BCD adjust to ASCII
						;  if low_nibble < 0Ah, low_nibble -= 6
						;  high_nibble -= 6

;--------------------------------------------------------------------------
; Write char in AL to console
;--------------------------------------------------------------------------
OUT_CHAR PROC
	PUSH	AX
	PUSH	BX
	XOR	BX, BX
	MOV	AH, 0EH			; Write AL to screen tty mode
	INT	10H				; send to console
	POP	BX
	POP	AX
	RET

OUT_CHAR ENDP
NIB_HEX ENDP
BYTE_HEX ENDP
WORD_HEX ENDP
DWORD_HEX ENDP

;----------------------------------------------------------------------------;
; Filter MDA attributes
;----------------------------------------------------------------------------;
; Remove underline, blink and ensure text is visible
;
; Input: BL attribute
; Ouput: BL (filtered)
;
; Size: 15 bytes
;----------------------------------------------------------------------------;
MDA_COLOR_FIX PROC
	PUSH	AX
	CALL	INT_10_IS_TXT			; CF if MDA
	JNC	MDA_COLOR_FIX_DONE		; exit if not MDA
	AND	BL, 01111111B			; remove MDA blink attr
	OR	BL, 0010B				; remove MDA underline attr
MDA_COLOR_FIX_DONE:
	POP	AX
	RET
MDA_COLOR_FIX ENDP

;----------------------------------------------------------------------------;
; Hide cursor display
;----------------------------------------------------------------------------;
; Clobbers CX
; Size: 16 bytes
;----------------------------------------------------------------------------;
HIDE_CURSOR PROC
	MOV	CX, 2000H			; hide cursor
	JMP	SHORT SET_CURSOR

;----------------------------------------------------------------------------;
; Show cursor display - restores saved cursor in CURSOR_DEFAULT
;----------------------------------------------------------------------------;
; Input:
; 	DS = BDA
; Clobbers CX
;----------------------------------------------------------------------------;
SHOW_CURSOR PROC
		ASSUME DS:_BDA
	MOV	CX, CURSOR_DEFAULT	; reset to original
SET_CURSOR:
	PUSH	AX
	MOV	AH, 1
	INT	10H
	POP	AX
	RET
SHOW_CURSOR ENDP
HIDE_CURSOR ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	GFX_CHARSET

;----------------------------------------------------------------------------;
; INT 1F - 8x8 Font bitmaps
;----------------------------------------------------------------------------;
; Font bitmaps from "VileR", (CC BY-SA 4.0)
; https://int10h.org/oldschool-pc-fonts/
;----------------------------------------------------------------------------;
		ORG 0FA6EH
GFX_CHARSET LABEL BYTE
	DB   000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H	; 00H
	DB   07EH, 081H, 0A5H, 081H, 0BDH, 099H, 081H, 07EH	; 01H
	DB   07EH, 0DBH, 0FFH, 0FFH, 0C3H, 0E7H, 07EH, 000H	; 02H
	DB   036H, 07FH, 07FH, 07FH, 03EH, 01CH, 008H, 000H	; 03H
	DB   008H, 01CH, 03EH, 07FH, 03EH, 01CH, 008H, 000H	; 04H
	DB   018H, 03CH, 018H, 066H, 0FFH, 066H, 018H, 03CH	; 05H
	DB   008H, 01CH, 03EH, 07FH, 07FH, 03EH, 008H, 01CH	; 06H
	DB   000H, 000H, 018H, 03CH, 03CH, 018H, 000H, 000H	; 07H
	DB   0FFH, 0FFH, 0E7H, 0C3H, 0C3H, 0E7H, 0FFH, 0FFH	; 08H
	DB   000H, 03CH, 066H, 042H, 042H, 066H, 03CH, 000H	; 09H
	DB   0FFH, 0C3H, 099H, 0BDH, 0BDH, 099H, 0C3H, 0FFH	; 0AH
	DB   03FH, 00DH, 01CH, 03EH, 063H, 063H, 03EH, 000H	; 0BH
	DB   03EH, 063H, 063H, 03EH, 01CH, 07FH, 01CH, 000H	; 0CH
	DB   00EH, 00FH, 00DH, 00DH, 01CH, 07FH, 01CH, 000H	; 0DH
	DB   00FH, 03BH, 037H, 03BH, 033H, 037H, 077H, 070H	; 0EH
	DB   018H, 0DBH, 03CH, 0E7H, 03CH, 0DBH, 018H, 000H	; 0FH
	DB   060H, 078H, 07EH, 07FH, 07EH, 078H, 060H, 000H	; 10H
	DB   003H, 00FH, 03FH, 07FH, 03FH, 00FH, 003H, 000H	; 11H
	DB   018H, 03CH, 07EH, 018H, 018H, 07EH, 03CH, 018H	; 12H
	DB   066H, 066H, 066H, 066H, 066H, 000H, 066H, 000H	; 13H
	DB   03FH, 06DH, 06DH, 03DH, 00DH, 00DH, 00DH, 000H	; 14H
	DB   03FH, 070H, 03EH, 063H, 063H, 03EH, 007H, 07EH	; 15H
	DB   000H, 000H, 000H, 000H, 0FFH, 0FFH, 0FFH, 000H	; 16H
	DB   03CH, 07EH, 018H, 018H, 07EH, 03CH, 018H, 07EH	; 17H
	DB   018H, 03CH, 07EH, 018H, 018H, 018H, 018H, 000H	; 18H
	DB   018H, 018H, 018H, 018H, 07EH, 03CH, 018H, 000H	; 19H
	DB   018H, 00CH, 006H, 07FH, 006H, 00CH, 018H, 000H	; 1AH
	DB   00CH, 018H, 030H, 07FH, 030H, 018H, 00CH, 000H	; 1BH
	DB   000H, 000H, 000H, 060H, 060H, 07FH, 000H, 000H	; 1CH
	DB   000H, 024H, 066H, 0FFH, 066H, 024H, 000H, 000H	; 1DH
	DB   008H, 01CH, 01CH, 03EH, 03EH, 07FH, 07FH, 000H	; 1EH
	DB   07FH, 07FH, 03EH, 03EH, 01CH, 01CH, 008H, 000H	; 1FH
	DB   000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H	; 20H  
	DB   018H, 018H, 018H, 018H, 018H, 000H, 018H, 000H	; 21H !
	DB   033H, 066H, 0CCH, 000H, 000H, 000H, 000H, 000H	; 22H "
	DB   036H, 036H, 07FH, 036H, 036H, 07FH, 036H, 036H	; 23H #
	DB   018H, 07EH, 058H, 038H, 01CH, 01AH, 07EH, 018H	; 24H $
	DB   0E3H, 0A6H, 0ECH, 018H, 037H, 065H, 0C7H, 000H	; 25H %
	DB   03CH, 066H, 03CH, 038H, 06DH, 066H, 03DH, 000H	; 26H &
	DB   006H, 00CH, 018H, 000H, 000H, 000H, 000H, 000H	; 27H '
	DB   01CH, 030H, 060H, 060H, 060H, 030H, 01CH, 000H	; 28H (
	DB   038H, 00CH, 006H, 006H, 006H, 00CH, 038H, 000H	; 29H )
	DB   063H, 036H, 01CH, 07FH, 01CH, 036H, 063H, 000H	; 2AH *
	DB   018H, 018H, 018H, 07EH, 018H, 018H, 018H, 000H	; 2BH +
	DB   000H, 000H, 000H, 000H, 000H, 018H, 018H, 030H	; 2CH ,
	DB   000H, 000H, 000H, 07EH, 000H, 000H, 000H, 000H	; 2DH -
	DB   000H, 000H, 000H, 000H, 000H, 018H, 018H, 000H	; 2EH .
	DB   002H, 006H, 00CH, 018H, 030H, 060H, 040H, 000H	; 2FH /
	DB   03EH, 063H, 063H, 06BH, 063H, 063H, 03EH, 000H	; 30H 0
	DB   01CH, 03CH, 00CH, 00CH, 00CH, 00CH, 00CH, 000H	; 31H 1
	DB   03EH, 063H, 003H, 00EH, 038H, 060H, 07FH, 000H	; 32H 2
	DB   07CH, 006H, 006H, 03CH, 006H, 006H, 07CH, 000H	; 33H 3
	DB   00EH, 01EH, 036H, 066H, 07FH, 006H, 006H, 000H	; 34H 4
	DB   07EH, 060H, 07CH, 006H, 006H, 006H, 07CH, 000H	; 35H 5
	DB   01EH, 030H, 060H, 07EH, 063H, 063H, 03EH, 000H	; 36H 6
	DB   07EH, 066H, 00CH, 018H, 030H, 030H, 030H, 000H	; 37H 7
	DB   03EH, 063H, 036H, 01CH, 036H, 063H, 03EH, 000H	; 38H 8
	DB   03EH, 063H, 063H, 03FH, 003H, 006H, 07CH, 000H	; 39H 9
	DB   000H, 000H, 018H, 018H, 000H, 018H, 018H, 000H	; 3AH :
	DB   000H, 000H, 018H, 018H, 000H, 018H, 018H, 030H	; 3BH ;
	DB   00CH, 018H, 030H, 060H, 030H, 018H, 00CH, 000H	; 3CH <
	DB   000H, 000H, 07EH, 000H, 07EH, 000H, 000H, 000H	; 3DH =
	DB   030H, 018H, 00CH, 006H, 00CH, 018H, 030H, 000H	; 3EH >
	DB   03EH, 063H, 006H, 00CH, 00CH, 000H, 00CH, 000H	; 3FH ?
	DB   03EH, 063H, 06FH, 069H, 06FH, 060H, 03FH, 000H	; 40H @
	DB   03CH, 066H, 066H, 07EH, 066H, 066H, 066H, 000H	; 41H A
	DB   07EH, 063H, 063H, 07EH, 063H, 063H, 07EH, 000H	; 42H B
	DB   01EH, 033H, 060H, 060H, 060H, 033H, 01EH, 000H	; 43H C
	DB   07CH, 066H, 063H, 063H, 063H, 066H, 07CH, 000H	; 44H D
	DB   07EH, 060H, 060H, 07CH, 060H, 060H, 07EH, 000H	; 45H E
	DB   07EH, 060H, 060H, 07CH, 060H, 060H, 060H, 000H	; 46H F
	DB   01EH, 033H, 063H, 060H, 067H, 033H, 01EH, 000H	; 47H G
	DB   063H, 063H, 063H, 07FH, 063H, 063H, 063H, 000H	; 48H H
	DB   03CH, 018H, 018H, 018H, 018H, 018H, 03CH, 000H	; 49H I
	DB   006H, 006H, 006H, 006H, 066H, 066H, 03CH, 000H	; 4AH J
	DB   063H, 066H, 06CH, 078H, 06CH, 066H, 063H, 000H	; 4BH K
	DB   030H, 030H, 030H, 030H, 030H, 030H, 03FH, 000H	; 4CH L
	DB   063H, 077H, 07FH, 06BH, 063H, 063H, 063H, 000H	; 4DH M
	DB   063H, 073H, 07BH, 06FH, 067H, 063H, 063H, 000H	; 4EH N
	DB   03EH, 063H, 063H, 063H, 063H, 063H, 03EH, 000H	; 4FH O
	DB   07EH, 063H, 063H, 07EH, 060H, 060H, 060H, 000H	; 50H P
	DB   03EH, 063H, 063H, 063H, 07BH, 06EH, 03CH, 007H	; 51H Q
	DB   07EH, 063H, 063H, 07EH, 06CH, 066H, 063H, 000H	; 52H R
	DB   03EH, 063H, 030H, 01CH, 006H, 063H, 03EH, 000H	; 53H S
	DB   07EH, 018H, 018H, 018H, 018H, 018H, 018H, 000H	; 54H T
	DB   063H, 063H, 063H, 063H, 063H, 063H, 03EH, 000H	; 55H U
	DB   063H, 063H, 063H, 063H, 036H, 01CH, 008H, 000H	; 56H V
	DB   063H, 063H, 063H, 06BH, 06BH, 07FH, 036H, 000H	; 57H W
	DB   063H, 063H, 036H, 01CH, 036H, 063H, 063H, 000H	; 58H X
	DB   063H, 063H, 063H, 03EH, 00CH, 00CH, 00CH, 000H	; 59H Y
	DB   07FH, 006H, 00CH, 018H, 030H, 060H, 07FH, 000H	; 5AH Z
	DB   03EH, 030H, 030H, 030H, 030H, 030H, 03EH, 000H	; 5BH [
	DB   040H, 060H, 030H, 018H, 00CH, 006H, 002H, 000H	; 5CH \
	DB   03EH, 006H, 006H, 006H, 006H, 006H, 03EH, 000H	; 5DH ]
	DB   01CH, 036H, 063H, 000H, 000H, 000H, 000H, 000H	; 5EH ^
	DB   000H, 000H, 000H, 000H, 000H, 000H, 000H, 0FFH	; 5FH _
	DB   030H, 018H, 00CH, 000H, 000H, 000H, 000H, 000H	; 60H `
	DB   000H, 000H, 03CH, 006H, 03EH, 066H, 03FH, 000H	; 61H a
	DB   060H, 060H, 07CH, 066H, 066H, 066H, 07CH, 000H	; 62H b
	DB   000H, 000H, 03EH, 063H, 060H, 060H, 03FH, 000H	; 63H c
	DB   006H, 006H, 03EH, 066H, 066H, 066H, 03EH, 000H	; 64H d
	DB   000H, 000H, 03CH, 066H, 07CH, 060H, 03EH, 000H	; 65H e
	DB   01EH, 030H, 030H, 07CH, 030H, 030H, 030H, 000H	; 66H f
	DB   000H, 000H, 03FH, 063H, 063H, 03FH, 003H, 07EH	; 67H g
	DB   060H, 060H, 06CH, 076H, 066H, 066H, 066H, 000H	; 68H h
	DB   018H, 000H, 038H, 018H, 018H, 018H, 018H, 000H	; 69H i
	DB   006H, 000H, 006H, 006H, 006H, 006H, 066H, 03CH	; 6AH j
	DB   060H, 060H, 066H, 06CH, 078H, 06CH, 066H, 000H	; 6BH k
	DB   018H, 018H, 018H, 018H, 018H, 018H, 00CH, 000H	; 6CH l
	DB   000H, 000H, 076H, 07FH, 06BH, 06BH, 063H, 000H	; 6DH m
	DB   000H, 000H, 06CH, 076H, 066H, 066H, 066H, 000H	; 6EH n
	DB   000H, 000H, 03EH, 063H, 063H, 063H, 03EH, 000H	; 6FH o
	DB   000H, 000H, 07CH, 066H, 066H, 07CH, 060H, 060H	; 70H p
	DB   000H, 000H, 03EH, 066H, 066H, 03EH, 006H, 006H	; 71H q
	DB   000H, 000H, 036H, 03BH, 030H, 030H, 030H, 000H	; 72H r
	DB   000H, 000H, 03EH, 070H, 03CH, 00EH, 07CH, 000H	; 73H s
	DB   018H, 018H, 07EH, 018H, 018H, 018H, 00EH, 000H	; 74H t
	DB   000H, 000H, 066H, 066H, 066H, 066H, 03BH, 000H	; 75H u
	DB   000H, 000H, 066H, 066H, 066H, 03CH, 018H, 000H	; 76H v
	DB   000H, 000H, 063H, 063H, 06BH, 07FH, 036H, 000H	; 77H w
	DB   000H, 000H, 063H, 036H, 01CH, 036H, 063H, 000H	; 78H x
	DB   000H, 000H, 066H, 066H, 066H, 03EH, 006H, 07CH	; 79H y
	DB   000H, 000H, 07EH, 00CH, 018H, 030H, 07EH, 000H	; 7AH z
	DB   00EH, 018H, 018H, 078H, 018H, 018H, 00EH, 000H	; 7BH {
	DB   018H, 018H, 018H, 000H, 018H, 018H, 018H, 000H	; 7CH |
	DB   070H, 018H, 018H, 00EH, 018H, 018H, 070H, 000H	; 7DH }
	DB   03BH, 06EH, 000H, 000H, 000H, 000H, 000H, 000H	; 7EH ~
	DB   018H, 03CH, 066H, 0C3H, 0C3H, 0FFH, 000H, 000H	; 7FH

;----------------------------------------------------------------------------;
; INT 1A - System and "Real Time" Clock BIOS Services
;----------------------------------------------------------------------------;
; INT 1A,0   Read system clock counter
; INT 1A,1   Set system clock counter
;----------------------------------------------------------------------------;
		ORG 0FE6EH
INT_1A PROC
		ASSUME DS:_BDA
	STI
	SUB	AH, 1 				; is function 0 or 1?
	JA	INT_1A_EXIT 			; if not, exit
	PUSH	DS
	PUSH	SI
	MOV	SI, SEG _BDA 			; get BDA segment
	MOV	DS, SI 				; DS = BDA
	MOV	SI, OFFSET TIMER_CT_L
	CLI 						; disable interrupts
	JZ	INT_1A_SET 				; if AH = 1, jump to Set clock

;----------------------------------------------------------------------------;
; INT 1A,0   Read system clock counter
;----------------------------------------------------------------------------;
; Return:
;	AL = midnight flag, 1 if 24 hours passed since reset
;	CX = high order word of tick count
;	DX = low order word of tick count
;----------------------------------------------------------------------------;
INT_1A_READ PROC
	LODSW 					; AX = low word of timer
	XCHG	AX, DX
	LODSW 					; AX = high word of timer
	XCHG	AX, CX
	XOR	AL, AL				; reset midnight flag to 0
	XCHG	AL, BYTE PTR[SI]			; AL = BDA flag, BDA = 0
INT_1A_DONE:
	STI 						; re-enable interrupts
	POP	SI
	POP	DS
INT_1A_EXIT:
	IRET
INT_1A_READ ENDP

;----------------------------------------------------------------------------;
; INT 1A,1   Set system clock counter
;----------------------------------------------------------------------------;
; Input:
;	AH = 0
;	CX = high order word of tick count
;	DX = low order word of tick count
;----------------------------------------------------------------------------;
INT_1A_SET PROC
	MOV	WORD PTR [SI], DX			; set low word ticks (seconds)
	MOV	WORD PTR [SI+2], CX		; set high word ticks (hours)
	MOV	BYTE PTR [SI+4], AH		; reset midnight flag
	JMP	SHORT INT_1A_DONE
INT_1A_SET ENDP

INT_1A ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	INT_08_PROC

		ORG 0FE97H
INT_08_PROC PROC
;----------------------------------------------------------------------------;
; INT 8 - Floppy Motor shutoff has elapsed - shut off motor
;----------------------------------------------------------------------------;
INT_08_MOTOR_OFF:
	MOV	AL, 11110000B 			; BDA motor off on all drives
	AND	FD_MOTOR_ST, AL			; clear BDA flags
	;AND	[DI][FD_MOTOR_ST-TIMER_CT_L], AL ; -1 byte vs AND FD_MOTOR_ST, AL
	XOR	AL, 11111100B 			; FDC motors off, DMA and FDC enable
	MOV	DX, FDC_CTRL 			; FD control port
	OUT	DX, AL 				; write to controller
	JMP	SHORT INT_08_INT_1C

;----------------------------------------------------------------------------;
; INT 8 - Timer
;----------------------------------------------------------------------------;
; - Run 18.2 times per second by PIT Timer
; - f = 1193180 / 10000H
; - Increment 32 bit counter, overflows at 24 hours + 9.67 sec
;	( 3600s/h - 65,536t / ( 1,193,180t/s / 65,536t ) ) * 24h = ~9.67s
; - Decrement floppy disk motor timeout counter
;  	  if reaches 0, turns off motor
; - only take jumps on special cases
;
; IMPORTANT NOTE: PC ROM BASIC's INT 1CH handler clobbers DX, so DX MUST
;  be call-preserved here.
;
; Bug fixes/suggestions thx to @Raffzahn
;----------------------------------------------------------------------------;
		ORG 0FEA5H
INT_08 PROC
		ASSUME DS:_BDA
	PUSH	AX 					; save AX, DX, DS and DI
	PUSH	DX					; workaround ROM BASIC INT 1Ch bug
	PUSH	DS
	PUSH	DI
	MOV	AX, SEG _BDA 			; DS = BIOS Data Area
	MOV	DS, AX

;----------------------------------------------------------------------------;
; Increment Timer
;
INT_08_TICK_TIMER:				; Advance the time ticker
	MOV	DI, OFFSET TIMER_CT_L 		; Low timer at BDA 0040:006C
	ADD	WORD PTR [DI], 1			; increment low word
	ADC	WORD PTR [DI+2], 0		; maybe increment high word
	CMP	WORD PTR [DI+2], 24 		; rolled over to next day?
	JAE	INT_08_TICK_DAY			; if so, check for day rollover

;----------------------------------------------------------------------------;
; Decrement Floppy Motor shutoff counter
;
INT_08_FD_MOTOR: 					; Check if there is a motor timeout
	STI						; interrupts back on
	DEC	FD_MOTOR_CT 			; increment counter, has reached 0?
	JZ	INT_08_MOTOR_OFF			; if so, turn off motor

;----------------------------------------------------------------------------;
; Call INT 1CH user vector
;
INT_08_INT_1C:
	INT	1CH					; call user timer hook

;----------------------------------------------------------------------------;
; Interrupt Complete - send EOI and return
;
INT_08_EOI:
	CLI						; disable interrupts for EOI
	MOV	AL, INT_EOI 			; End of Interrupt OCW
	OUT	INT_P0, AL				; write EOI to port 0
	POP	DI
	POP	DS
	POP	DX					; restore DX
	POP	AX
	IRET

;----------------------------------------------------------------------------;
; Check if day has rolled over (24H + 9.67s) and reset 32 bit ticker if so
;
INT_08_TICK_DAY:
	CMP	BYTE PTR [DI], 176 		; has day rolled over?
	JB	INT_08_FD_MOTOR			; if not, handle FD motor timeout

;----------------------------------------------------------------------------;
; Timer has rolled over 24 hours - reset counters and set overflow flag
;
INT_08_RESET:
	XOR	AX, AX 				; AX = 0
	MOV	WORD PTR [DI], AX			; TIMER_CT_L = 0
	MOV	WORD PTR [DI+2], AX		; TIMER_CT_H = 0
	INC	AX 					; AL = 1
	MOV	BYTE PTR [DI+4], AL		; TIMER_CT_OF = 1
	JMP	INT_08_FD_MOTOR			; continue and check motor

INT_08 ENDP
INT_08_PROC ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	VECTOR_TABLE

;----------------------------------------------------------------------------;
; Interrupt Vector Table template
;----------------------------------------------------------------------------;
; These fill the IVT prior to bootstrap.
;----------------------------------------------------------------------------;
			ORG 0FEE3H
VECTOR_TABLE PROC
	DW  OFFSET INT_IRQ 		; int 00	INT_IRQ
	DW  OFFSET INT_IRQ 		; int 01	INT_IRQ
	DW  OFFSET INT_02 		; int 02	INT_02 - NMI
	DW  OFFSET INT_IRQ 		; int 03	INT_IRQ
	DW  OFFSET INT_IRQ 		; int 04	INT_IRQ
	DW  OFFSET INT_05 		; int 05	INT_05 - Print Screen
	DW  OFFSET INT_IRQ 		; int 06	INT_IRQ
	DW  OFFSET INT_IRQ 		; int 07	INT_IRQ

;----------------------------------------------------------------------------;
; Compatibility fixed ORG for INT 08 - 1Eh
;
			ORG 0FEF3H
	DW  OFFSET INT_08 		; int 08	IRQ0 - System timer
	DW  OFFSET INT_09_POST		; int 09	IRQ1 - Keyboard IRQ (during POST)
	DW  OFFSET INT_IRQ		; int 0A	IRQ2 - INT_DEFAULT
	DW  OFFSET INT_IRQ		; int 0B	IRQ3 - COM2
	DW  OFFSET INT_IRQ		; int 0C	IRQ4 - COM1
	DW  OFFSET INT_IRQ		; int 0D	IRQ5 - XT FDC
	DW  OFFSET INT_0E			; int 0E	IRQ6 - Floppy Controller
	DW  OFFSET INT_IRQ		; int 0F	IRQ7 - LPT
	DW  OFFSET INT_10			; int 10	INT_10 - Video
	DW  OFFSET INT_11			; int 11	INT_11 - Equipment Check
	DW  OFFSET INT_12			; int 12	INT_12 - Memory Size
	DW  OFFSET INT_13			; int 13	INT_13 - Floppy Disk
	DW  OFFSET INT_14			; int 14	INT_14 - Serial Port
	DW  OFFSET INT_15			; int 15	INT_15 - System Services
	DW  OFFSET INT_16			; int 16	INT_16 - Keyboard Services
	DW  OFFSET INT_17			; int 17	INT_17 - Printer
	DW  OFFSET INT_18 		; int 18	INT_18 - Unbootable/ROM BASIC
	DW  OFFSET INT_19			; int 19	INT_19 - Bootstrap
	DW  OFFSET INT_1A			; int 1A	INT_1A - Time of day
	DW  OFFSET INT_RET 		; int 1B	INT_1B - Ctrl Brk
	DW  OFFSET INT_RET 		; int 1C	INT_1C - Timer Tick
	DW  OFFSET INT_1D 		; int 1D	INT_1D - CRTC param table
	DW  OFFSET INT_1E 		; int 1E	INT_1E - Floppy param table
	DW  0 				; int 1F	INT_1F - 8x8 (CP 128-255) video font table
L_VECTOR_TABLE	EQU ($-VECTOR_TABLE)/2	; 20h (32) vectors
VECTOR_TABLE ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	INT_IRQ

;----------------------------------------------------------------------------;
; INT_IRQ - Handle placeholder hardware interrupts
;----------------------------------------------------------------------------;
; ISR for any hardware interrupts that have yet to be vectored.
; Acknowledge interrupt and write last HW interrupt to BDA.
;
; Output:
;	INT_LAST = last interrupt or 0xFF if non-hardware/unknown interrupt
;----------------------------------------------------------------------------;
		ORG 0FF23H
INT_IRQ PROC
			ASSUME DS:_BDA
	PUSH	AX 				; save registers
	PUSH	BX
	MOV	BX, SEG _BDA 		; set up for DS to BDA
	MOV	AX, 0FF00h OR 00001011b	; AL = OCW3 Control Word (Read ISR reg on next pulse)
						; AH = default return 0xFF in INT_LAST
	OUT	INT_P0, AL			; write to PIC port 0 (20h)
	PUSH	DS				; save DS and delay for PIC at least 1 clock pulse
	IN	AL, INT_P0			; get In-Service Register (ISR)
	TEST	AL, AL 			; is there an active hardware interrupt?
	JZ	INT_IRQ_DONE		; jump and exit if not
	MOV	AH, AL 			; Save ISR in AH
	IN	AL, INT_P1			; get current Interrupt Mask Register (IMR)
	MOV	DS, BX			; set DS to BDA
	MOV	INT_LAST, AH	 	; save last interrupt to BDA and delay for PIC
	OR	AL, AH 			; apply IMR mask to ISR
	OUT	INT_P1, AL			; write AL to PIC port 1 (21h)
	MOV	AL, INT_EOI 		; End of Interrupt OCW
	OUT	INT_P0, AL			; write EOI to PIC port 0 (20h)
INT_IRQ_DONE:
	POP	DS
	POP	BX
	POP	AX
	IRET

INT_IRQ ENDP

;----------------------------------------------------------------------------;
; Write a space char to console (9 bytes)
;----------------------------------------------------------------------------;
SPACE PROC
	PUSH	AX				; no clobbery AX
	MOV	AX, 0E00H OR ' '		; AH = 0Eh, AL = space char
	INT	10H				; send to console
	POP	AX
	RET
SPACE ENDP

; 1 BYTE HERE

BYTES_HERE	INT_RET

;----------------------------------------------------------------------------;
; INT_RET - Handle placeholder software interrupts
;----------------------------------------------------------------------------;
	ORG 0FF53H
INT_RET PROC
	IRET
INT_RET ENDP

;----------------------------------------------------------------------------;
; INT 5 - Print Screen
;----------------------------------------------------------------------------;
; Print the contents of the current screen/page.
;
; Output:
; - Screen contents to PRN (BIOS printer 0)
; - Status to BDA 50:0H:
;	00	Print screen has not been called, or upon return
;			from a call there were no errors
;	01	Print screen is already in progress
;	FF	Error encountered during printing
;----------------------------------------------------------------------------;
; Things you must do:
; 	1. Check status (BDA 50:0H) to ensure PrtScn is not already in progress.
;	2. Set working status to 1.
;	3. Get the current screen size (columns) and video page.
;	4. Save the current cursor position, then move to the top.
;	5. Read the char at that position and send to printer.
;	6. If last column reached, move screen cursor to start of next line
;		and send CR and LF to printer to start new line.
;	7. Keep looping until past the last row (always 25)
;	8. Restore screen cursor position
;	9. Set BDA status to either success (0) or error (-1)
;----------------------------------------------------------------------------;
	ORG 0FF54H
INT_05 PROC
			ASSUME DS:_BDA
	CLD						; string direction forward
	PUSH	AX
	PUSH	DI
	PUSH	ES
	MOV	DI, SEG _DOS_DAT
	MOV	ES, DI				; ES = seg 50H
	XOR	DI, DI				; DI = PTRSCN_ST
	MOV	AL, 1					; print status = 1 (in progress)
	SCASB						; is in progress already?
	JZ	INT_05_EXIT				; if so, exit
	STI						; Interrupts should be okay now
	DEC	DI					; undo earlier SCASB increment
	STOSB						; update status to 1
	PUSH	BX					; preserve working registers
	PUSH	CX
	PUSH	DX
	MOV	AH, 0FH				; get video state (columns)
	INT	10H					; AH = screen columns, BH = page
	MOV	BL, AH				; BL = screen columns
	DEC	BX					; fix 0 index
	MOV	AH, 3					; get cursor position
	INT	10H					; DH = cursor row, DL = cursor column
	PUSH	DX					; save starting cursor position
	XOR	DX, DX				; start position at row 0, col 0
	;CWD						; (unsafe, can't trust an INT 10h)
INT_05_LOOP_1:
	MOV	AH, 2					; set cursor position
	INT	10H					; set cursor to DH=row, DL=col
	MOV	AH, 8					; get char/attr at current position
	INT	10H					; AL = char at current position 
	CALL	LPT_CHAR				; print char in AL
	JNZ	INT_05_PRINT_ERR			; exit if print error
	CMP	BL, DL				; end of screen cols? 
	JNZ	INT_05_NEXT_COL			; jump if not  
	MOV	DL, -1				; else move to first col and next row
	CALL	LPT_CRLF				; CR and LF to PRN
	JNZ	INT_05_PRINT_ERR			; exit if print error
INT_05_NEXT_COL:
	INC	DX					; move to next column (and maybe row)
	CMP	DH, VID_DEF_ROWS+1		; end of screen rows?
	JNZ	INT_05_LOOP_1			; loop while not last row
	MOV	AL, 0					; print status = 0 (success)
INT_05_DONE:
	CLI						; make sure this completes w/o other INTs
	DEC	DI					; undo earlier STOSB increment
	STOSB						; update BDA status
	POP	DX					; restore starting cursor position
	MOV	AH, 2					; set cursor position in DH/DL
	INT	10H
	POP	DX
	POP	CX
	POP	BX
INT_05_EXIT:
	POP	ES
	POP	DI
	POP	AX
	IRET
INT_05_PRINT_ERR:
	MOV	AL, -1				; print status = 0FFH (error)
	JMP	SHORT INT_05_DONE

;----------------------------------------------------------------------------;
; LPT_CRLF - Write CR and LF to PRN
;----------------------------------------------------------------------------;
LPT_CRLF PROC
	MOV	AL, CR
	CALL	LPT_CHAR
	JNZ	LPT_CHAR_EXIT			; exit if print error

;----------------------------------------------------------------------------;
; LPT_LF - Write LF to PRN
;----------------------------------------------------------------------------;
LPT_LF PROC
	MOV	AL, LF

;----------------------------------------------------------------------------;
; LPT_CHAR - Write a char to PRN
;----------------------------------------------------------------------------;
; Input:
;	AL = char to print
; Output:
;	AH = Print Flags
;	ZF = 0 (NZ) if timeout
;
; AL clobbered if null
;----------------------------------------------------------------------------;
LPT_CHAR PROC
	PUSH	DX
	XOR	DX, DX				; DX = printer 0 (PRN)
	TEST	AL, AL				; was input char a null?
	JNZ	LPT_CHAR_OUT			; jump if not
	MOV	AL, ' '				; if so, use a space
LPT_CHAR_OUT:
	MOV	AH, 0					; Print Character function
	INT	17H					; Print AL to PRN0
	TEST	AH, 00000001B			; ZF = 0 if timeout
	POP	DX
LPT_CHAR_EXIT:
	RET
LPT_CHAR ENDP
LPT_LF ENDP
LPT_CRLF ENDP

INT_05 ENDP

;----------------------------------------------------------------------------;
; Check if a 8087 FPU is present and perform quick tests
;----------------------------------------------------------------------------;
; Input:
;	AX = any non-zero value
; Output:
;	ZF = 0 if no FPU, ZF = 1 if present
;
; Clobbers: AX, BX
;
; Sources:
;   https://retrocomputing.stackexchange.com/questions/16529/detecting-the-external-x87-fpu
;   Intel(R) App Note AP-485 "Intel(R) Processor Identification and the CPUID Instruction"
;----------------------------------------------------------------------------;
HAS_FPU PROC
	FNINIT 					; reset FPU, no wait

;----------------------------------------------------------------------------;
; Test Status Word
;
FPU_TEST_SW:
	PUSH	AX 					; init temp word to non-zero
	MOV	BX, SP	 			; use stack memory
	FNSTSW WORD PTR SS:[BX]			; store status word
	NOP						; delay to allow FPU to complete
	POP	AX 					; AX = control word if FNSTCW executed
	TEST	AL, AL 				; check exception flags
	JNZ	FPU_TEST_DONE			; if flags = 00, FPU is present

;----------------------------------------------------------------------------;
; Test Control Word
;
FPU_TEST_CW:
	PUSH	AX
	FNSTCW WORD PTR SS:[BX]			; store control word
	NOP						; delay to allow FPU to complete
	POP	AX 					; AX = control word
	AND	AX, 0103FH 				; isolate interesting status flags
	CMP	AX, 03FH 				; check for 8087 "signature"
							; ZF = 0 if no FPU
FPU_TEST_DONE:
	RET
HAS_FPU ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	VER

;-------------------------------------------------------------------------
; Version and Build Strings
;
VER_STRING_ORG	EQU	_X86_RESET-(VER_END-VER)
		ORG	0FFE1H		; use VER_STRING_ORG for this
VER:
	DB	'Ver: '
	DB	VER_NUM
				IF POST_SHOW_VER GT 1
	DB	'-'				; Show CPU type and
	DB	CPU_TYPE			; architecture target
	DB	ARCH_TYPE
;				IF POST_SHOW_VER GT 2 ; (not enough bytes for this)
;	DB	' '
;	DB	VER_BLD			; show build #
;				ENDIF
				ENDIF
	DB	' '
	DB	0

VER_END:

;
; 0 BYTES HERE
;
BYTES_HERE	_X86_RESET

;----------------------------------------------------------------------------;
; F000:FFF0: 8086 power-on reset vector
;----------------------------------------------------------------------------;
; The x86 CPU begins code excution at hard-coded address F000:FFF0.
; This is that address. Welcome to the party!
;----------------------------------------------------------------------------;
		ORG	0FFF0H
_X86_RESET	LABEL FAR
	JMP	FAR PTR _COLD_BOOT 	; always jump to cold boot routine

		ORG	0FFF5H
REL_DATE 	DB	VER_DATE		; Release date

		ORG	0FFFEH
ISA_TYPE	DB	ARCH_ID		; Architecture model

		ORG	0FFFFH		; BIOS ROM checksum byte 
		DB	?			; (computed at build time)

_BIOS		ENDS

;============================================================================;
;
;				* * *    END OF BIOS   * * *
;
;============================================================================;

;-------------------------------------------------------------------------
; Fixed BIOS Entry Points
;-------------------------------------------------------------------------
; The fixed entry points in F000:xxxx must be supported for compatibility
; reasons. The table below lists the fixed BIOS entry points.
;
;  X = complete
;-------------------------------------------------------------------------
;  X	F000:E05B	POST Entry Point
;  X	F000:E2C3	INT 02: NMI Entry Point
;  X	F000:E6F2	INT 19: Entry Point
;  X	F000:E739	INT 14: Serial Port
;  X	F000:E82E	INT 16: Keyboard Services
;  X	F000:E987	INT 09: Keyboard IRQ1
;  X	F000:EC59	INT 13: Floppy Services
;  X	F000:EF57	INT 0E: Floppy IRQ6
;  X	F000:EFC7	INT 1E: Floppy Disk Controller Parameter Table
;  X	F000:EFD2 	INT 17: Printer
;  X	F000:F065	INT 10: MDA/CGA Video Services
;  X	F000:F0A4	INT 1D: MDA/CGA Video Parameter Table
;  X	F000:F841	INT 12: Memory Size
;  X	F000:F84D	INT 11: Equipment Check
;  X	F000:F859	INT 15: System Services
;  X	F000:FA6E	INT 1F: 8x8 Font bitmaps high 128 CPs of graphic video font
;  X	F000:FE6E	INT 1A: Time of day
;  X	F000:FEA5	INT 08: System timer IRQ0
;  X	F000:FEF3	Initial Interrupt Vector Table (INTs 08-1F)
;  X	F000:FF23	INT IRQ: Placeholder IRQ Handler
;  X	F000:FF53	INT IRET: Dummy Interrupt Handler
;  X	F000:FF54	INT 05: Print Screen
;  X	F000:FFF0	Power-On Entry Point
;  X	F000:FFF5	ROM Date in ASCII "MM/DD/YY" for 8 characters
;  X	F000:FFFE	System Model 0xFF, 0xFE or 0xFB
;-------------------------------------------------------------------------
; Source:
;   Intel(R) Platform Innovation Framework for EFI 
;   Compatibility Support Module Specification 
;   Rev 0.97
; https://www.intel.com/content/dam/doc/reference-guide/efi-compatibility-support-module-specification-v097.pdf
;-------------------------------------------------------------------------

END

;----------------------------------------------------------------------------;
; Text Auto-Formatting:
;----------------------------------------------------------------------------;
; Sublime Text syntax:
; {
; 	"tab_completion": false,
;	"auto_complete": false,
;	"tab_size": 6,
; }
;----------------------------------------------------------------------------;
;
; Modeline magic for various editors
;
; /* vim: set tabstop=6:softtabstop=6:shiftwidth=6:noexpandtab */
; # sublime: tab_completion false; auto_complete vfalsealue; tab_size 6
