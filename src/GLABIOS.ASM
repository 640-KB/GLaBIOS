	PAGE	 	59,132
	TITLE		GLaBIOS

;----------------------------------------------------------------------------;
; GLaBIOS (General Libraries and Basic Input Output System)
;
; A scratch-built, open-source 8088 PC/clone BIOS alternative.
;
; Copyright (c) 2022-2025, 640KB and contributors
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
; References, Credits and Inspiration:
;
;  https://stanislavs.org/helppc/
;  http://www.minuszerodegrees.net/
;  https://www.felixcloutier.com/x86/
;  https://sites.google.com/site/pcdosretro/ (offline)
;
;  "Programmer's Guide to the IBM(R) PC", Peter Norton
;  "System BIOS for IBM(R) PC/XT(TM)/AT(R) Computers and Compatibles",
;	Phoenix Technologies Ltd.
;  "Programmer's Guide to PC Video Systems", Second Edition, Wilton
;  (Many more inline...)
;
;  @Raffzahn, Contributor and Meckerhut.
;
;  https://github.com/640-KB/GLaBIOS#further-credits-to
;
;  "Every byte is sacred, every byte is great,
;  when a byte is wasted, God gets quite irate..."
;  - David W. Plummer
;----------------------------------------------------------------------------;
; Build Instructions:
;
; Build with MASM 5.0 or MASM 6.
;
;  MAKE.BAT
;
; or
;
;  MASM GLABIOS;
;  LINK GLABIOS;
;  GLA2ROM GLABIOS.EXE GLABIOS.ROM		; Build 8K ROM
;
; MASM Build Options:
;  /DVER_DATE='02/22/22'			; Must be MM/DD/YY format
;  /DARCH_TYPE='X'				; P, X, Y or T (see ARCH_* below)
;  /DCPU_TYPE='8'					; 8 or V (see CPU_* below)
;
;----------------------------------------------------------------------------;
; POST Error Beep messages:
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
;
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Build Target Architecture equates (do not edit these)
;
ARCH_5150		EQU	'P'			; 5150
ARCH_5160		EQU	'X'			; 5160 v1
ARCH_5160v2		EQU	'Y'			; 5160 v2/3
ARCH_TURBO		EQU	'T'			; Standard Turbo or clone
ARCH_TD3300		EQU	'S'			; TD3300A, VDL C1, D-11
ARCH_FE2010		EQU	'F'			; Faraday FE2010A
ARCH_EHB		EQU	'H'			; EMM Computers/Homebrew8088
ARCH_EMU		EQU	'E'			; 86Box/Emulator
ARCH_M88		EQU	'M'			; micro_8088/NuXT
ARCH_MIST		EQU	'I'			; PCXT_MiSTer
ARCH_UM82		EQU	'U'			; UMC UM82C088, ALi M1101, TACT80101FT
ARCH_MARTY		EQU	'C'			; MartyPC Emulator
ARCH_VEN888		EQU	'V'			; Vendex 888-XT
ARCH_LASER		EQU	'L'			; VTech Laser Turbo XT
ARCH_BOOK88		EQU	'B'			; Book 8088
ARCH_CPQ		EQU	'Q'			; Compaq Portable XT
ARCH_VIRTUALXT	EQU	'J'			; VirtualXT Emulator
ARCH_NEST		EQU	'N'			; Juko Nest N3 (D-11 chipset)

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
BOOT_MEDIUM		EQU	'M'			; used by FE2010A

;
; Turbo Switch Behavior
;
TURBO_NONE		EQU	0			; fixed clock no turbo switching
TURBO_STD		EQU	1			; standard PPI (1=turbo, 0=normal)
TURBO_REV		EQU	2			; reversed PPI (0=turbo, 1=normal)

;----------------------------------------------------------------------------;
; BIOS Product Info
;
VER_NAME		EQU	'GLaBIOS'
	IFNDEF VER_NUM
VER_NUM		EQU	'0.4.0'		; (max 5 chars)
	ENDIF
	IFNDEF VER_DATE
VER_DATE		EQU	'07/17/25'		; must be MM/DD/YY per Intel CSM
	ENDIF
COPY_YEAR		EQU	'2022-25'		; Copyright year range

;----------------------------------------------------------------------------;
; BEGIN Configurable Build Options
;----------------------------------------------------------------------------;
; Very important note on custom configuration:
;
; Not all options can be combined due to very limited ROM code space of 8K,
; and fitting withing fixed compatibility ORGs.
;
; For experimenting with build options, it's highly recommended to use
; MASM 5.0 as it will not build if code space is exceeded. Due to differences
; in MASM 6, this does not work and can produce a totally broken build.
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Select Target Architecture Preset
;
	IFNDEF ARCH_TYPE
;ARCH_TYPE		EQU	ARCH_5150		; PC 5150
;ARCH_TYPE		EQU	ARCH_5160		; PC 5160 (recommended for non-Turbo)
ARCH_TYPE		EQU	ARCH_TURBO		; Standard Turbo
;ARCH_TYPE		EQU	ARCH_TD3300		; TD3300A (ST-xx/UNIQUE/Auva)
;ARCH_TYPE		EQU	ARCH_FE2010		; Faraday FE2010A
;ARCH_TYPE		EQU	ARCH_UM82		; UMC UM82C088 / ALi M1101
;ARCH_TYPE		EQU	ARCH_EHB		; EMM Computers/Homebrew 8088
;ARCH_TYPE		EQU	ARCH_EMU		; 86Box/Emulators (not for real hardware)
;ARCH_TYPE		EQU	ARCH_BOOK88		; Book 8088
	ENDIF

;----------------------------------------------------------------------------;
; Sub Architecture Types (use with the ARCH_TYPE in parentheses)
;
	IFNDEF ARCH_SUB_TYPE
;ARCH_SUB_TYPE	EQU	ARCH_5160v2		; PC 5160v2/v3 (TYPE ARCH_5160)
;ARCH_SUB_TYPE	EQU	ARCH_M88		; micro_8088/NuXT (TYPE ARCH_FE2010)
;ARCH_SUB_TYPE	EQU	ARCH_MIST		; PCXT_MiSTer (TYPE ARCH_EMU)
;ARCH_SUB_TYPE	EQU	ARCH_MARTY		; MartyPC Emulator (TYPE ARCH_TURBO)
;ARCH_SUB_TYPE	EQU	ARCH_VIRTUALXT	; VirtualXT Emulator (TYPE ARCH_TURBO)
;ARCH_SUB_TYPE	EQU	ARCH_VEN888		; Vendex 888-XT (TYPE ARCH_TURBO)
;ARCH_SUB_TYPE	EQU	ARCH_NEST		; Juko Nest N3 (TYPE ARCH_TD3300)
	ENDIF

;----------------------------------------------------------------------------;
; Default CPU Instruction Set Target
;
	IFNDEF CPU_TYPE
CPU_TYPE		EQU	CPU_8088		; CPU_8088 or CPU_V20
;CPU_TYPE		EQU	CPU_V20		; use V20+ only instructions
	ENDIF

;----------------------------------------------------------------------------;
; Turbo Type
;
; Some motherboards boot in Normal mode by default and the BIOS may or may not
; switch to Turbo speed on boot. Others invert this behavior where it appears
; reversed to the BIOS. Use these options to customize for your motherboard.
;
	IFNDEF TURBO_TYPE
;TURBO_TYPE		=	TURBO_NONE	; standard 4.77 MHz
;TURBO_TYPE		=	TURBO_STD	; standard PPI 61h (1=turbo, 0=normal)
TURBO_TYPE		=	TURBO_REV	; reversed PPI 61h (1=normal, 0=turbo)
	ENDIF

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
POST_THEME		=	1		; color theme for POST screen (see below)
POST_CLS		=	0		; clear screen after POST
POST_GLADOS		=	0		; say "Starting GLaDOS..." on boot
POST_CONFIG		=	1		; show CPU, FPU and ports on POST
POST_FD_COUNT	=	1		; show floppy drive count on POST
POST_HD_COUNT	=	1		; show hard drive count and params on POST
POST_HD_PARMS	=	1		; show hard drive parameters on POST
POST_OPT_ROM	=	1		; show option ROM address and loading info
POST_VIDEO_TYPE	=	1		; show the video adapter type on POST
POST_WARM_COLD	=	1		; show boot WARM or COLD
POST_BANNER		=	1		; show banner and version
WARM_ENABLE		=	1		; 1=enable WARM boot or 0=always COLD boot
RANDOM_TAGLINE	=	1		; randomize pithy tagline
UNITS_IEC		=	0		; 0=period-correct "KB" or 1=modern IEC "KiB"

;----------------------------------------------------------------------------;
; Enable/Disable POST tests (not all tests can be enabled due to 8K ROM space)
;
POST_TEST_INST	=	0		; POST CPU Instruction/Flag Test
POST_TEST_DMA	=	1		; POST DMA Register Test
POST_TEST_DMA_TC0	=	1		; POST DMA Terminal Count Test
POST_TEST_PIT_1	=	1		; POST Timer Channel 1 Test
POST_TEST_PIC_REG	=	1		; POST PIC Register Test
POST_TEST_PIC_INT	=	1		; POST PIC Interrupt Test
POST_TEST_CHK_ROM	=	1		; POST Checksum ROM
POST_TEST_FD	=	1		; POST Floppy Drive Test
POST_TEST_SEEK	=	1		; POST Seek Floppy Drives
POST_TEST_KB	=	1		; POST Keyboard Test (PKI)
POST_TEST_KEY	=	1		; POST Key Test (PKEY)

;----------------------------------------------------------------------------;
; Advanced Options (may void your warranty)
;
MAX_RAM_PC		EQU	640		; 640K: base 0000-A000 (for EGA/VGA)
MAX_RAM_MDA		EQU	704		; 704K: include A000-B000 (for MDA)
MAX_RAM_CGA		EQU	736		; 736K: include A000-B800 (for CGA)
MAX_RAM 		=	MAX_RAM_PC	; Max detectable low RAM (in KB)
MAX_RAM_AUTO	=	0		; Auto-detect MAX_RAM from video DIP switches
DRAM_REFRESH	=	18		; DRAM refresh divisor 1.193 MHz/18 = 66,287.87 Hz
						; 0=Disable refresh (use only with SRAM!)
RAM_PARITY		=	1		; Enable RAM parity checking
RAM_TEST_LONG	=	1		; Long RAM test on cold boot
RAM_DIGITS		=	3		; Number of zero-padded digits for RAM (3 or 4)
BASIC_ROM		=	1		; BASIC ROM support at 0F600h
OPT_ROM_END		=	0FE00H	; Option ROM scan ending address (must be xx00)
FDC_ENABLE		=	1		; Enable INT 13h floppy support
FDC_IPL_SW		=	0		; Use IPL switch to enable/disable floppy
FDC_HLT_WAIT	=	1		; Halt CPU during FD access
						;   Some chipsets (TD3300A known affected)
						;   hang during floppy access if this is
						;   enabled
FDC_ADV_SEEK	=	1		; Advanced floppy seeking performance
						;   Store current head position in BDA
						;   to avoid unnecessary seek commands
FDC_ZERO_BDA	=	0		; clear FDC FIFO buffer between ops
						;   Some HD ROMs appropriate this memory
FDC_ERR_SEC_CT	=	0		; On error, 0=always return 0 sectors
						;   1=return partial/successful sector count
KB_HLT_WAIT		=	1		; Halt CPU during KB wait
MBR_CHECK		=	0		; Verify magic number of DOS MBR at boot
						;   note: DOS 1.0 does not use MBR, so
						;   will not boot if this is enabled
POST_HD_CHECK	=	1		; Enable POST HD drive count and size
						;   note: Some older WD controller ROMs
						;   (version 62-000043-0xx known affected)
						;   have bugs where INT 13h function are
						;   unusable during POST. Set to 0 to
						;   work around (disables POST_HD_PARMS)
FD_AUTO_DETECT	=	0		; Auto-detect number of floppy drives
						;   use only for DIP switch-less PCs!
POST_ERR_WAIT	=	1		; Wait for Any Key press to continue if
						;   there is a POST error
INT_19_BOOT_HD	=	0		; Try IPL to floppy then hard drive (80h)
SW1_FLP		=	MASK FLP	; Default max number of floppy drives
MDA_ATTR		=	1		; Display MDA character attributes
						; 2=all, 1=intensity only, 0=filter all
LIGHT_PEN		=	1		; INT 10h,4 light pen support
EXP_UNIT		=	0		; Init 5161 I/O Expansion Unit
KB_FILTER_SC	=	0		; Filter KB make/break code >= 70h
INIT_AT_KBC		=	0		; Init AT type KB controller
INIT_V40		=	0		; Init V40 config registers
OEM_FONT		=	0		; 1=use OEM style font, 0=clone style
POST_CARD		=	0		; enable POST codes on port 80H
MUTE_TANDY		=	0		; mute buzzing on Tandy 3 Voice
MUSHROOM_HACK	=	0		; workaround delay if PIT is stopped
FE_CONF_LOCK	=	1		; lock FE2010 config register after init
ROM_SCAN_ALIGN	=	1		; option ROM scan aligns to 2K boundaries
OEM_KB_EXT		=	1		; allow EAh reset byte on ext. keyboard

;----------------------------------------------------------------------------;
; Hardware hacks!
; These run your system way out of spec. You have been warned.
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; UNSAFE_FLOPPY: Reduce floppy drive head settling time for possibly faster
; seek access and burst transfer reads. Warning: this may result in drive
; read errors on some hardware.
; Specify UNSAFE_FLP_DIV as percentage of head settling time, as configured
; in DBT.
;
UNSAFE_FLOPPY	=	0		; Use % of specified disk head settle time
;UNSAFE_FLP_DIV	EQU	<1/3>		; 33%
UNSAFE_FLP_DIV	EQU	<3/10>	; 30%
;UNSAFE_FLP_DIV	EQU	<1/4>		; 25%

;	IF FDC_ADV_SEEK EQ 1
;UNSAFE_FLOPPY	=	1		; reduce head settle times with FDC_ADV
;UNSAFE_FLP_DIV	EQU	<1/2>		; 50%
;	ENDIF

;----------------------------------------------------------------------------;
; UNSAFE_REFRESH: Lower the amount of time spent in DMA/DRAM refresh state.
; Depending on hardware configuration, this may result in significant speed
; and performance gains of up to 5 to 10%, or it may result in instability
; and parity errors.
;
; This is similar to programs such as "SPEEDER" or "FASTV20", which lowers
; refresh from 1/18 (65K/s) to 1/64 (18K/s) and 1/655 (1.8K/s) respectively.
;
; https://forum.vcfed.org/index.php?threads/fastv20-com.24005/
; https://www.pcorner.com/list/UTILITY/SPEEDER.ZIP/INFO/
; https://www.reenigne.org/blog/how-to-get-away-with-disabling-dram-refresh/
; https://en.wikipedia.org/wiki/Memory_refresh
;
UNSAFE_REFRESH	=	0		; Use unsafe DRAM refresh timing
	IF UNSAFE_REFRESH EQ 1
DRAM_REFRESH	=	655		; "FASTV20" DRAM divisor: 1,821.65 Hz
;DRAM_REFRESH	=	64		; "SPEEDER" DRAM divisor: 18,640 Hz
	ENDIF

;----------------------------------------------------------------------------;
; END Configurable Build Options
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; ARCH/build-specific configuration
;----------------------------------------------------------------------------;
; Defaults / BIOS ID Byte
;
; https://stanislavs.org/helppc/id_bytes.html
;
ARCH_ID		=	0FEH			; 0xFE=XT v1/clone (default)
CASSETTE		=	0			; disable cassette (default)

	IFNDEF ARCH_SUB_TYPE
ARCH_SUB_TYPE	EQU	0			; make sure this is defined
	ENDIF

	IF ARCH_TYPE EQ ARCH_5150
;----------------------------------------------------------------------------;
; Configuration for 5150 board
;
ARCH_ID		=	0FFH			; 0xFF=5150
CASSETTE		=	1			; enable INT 13h cassette
MBR_CHECK		=	0			; disable MBR check for DOS 1.x
;FDC_IPL_SW		=	1			; Use IPL SW1 for drive count
TURBO_TYPE		=	TURBO_NONE
EXP_UNIT		=	1			; enable Expansion Unit
OEM_FONT		=	1			; use OEM style font
POST_TEST_DMA_TC0	=	0			; OEM 5150 BIOS does not do this test
	ENDIF

;----------------------------------------------------------------------------;
; Configuration for 5160 boards
;
	IF ARCH_TYPE EQ ARCH_5160
TURBO_TYPE		=	TURBO_NONE		; disable Turbo features
FDC_IPL_SW		=	1			; Use IPL SW1 for drive count
EXP_UNIT		=	1			; enable Expansion Unit
OEM_FONT		=	1			; use OEM style font
	ENDIF
	IF ARCH_SUB_TYPE EQ ARCH_5160v2
ARCH_ID		=	0FBH			; 0xFB=XT v2/v3
FDC_IPL_SW		=	0			; Don't use IPL SW1 for drive count
	ENDIF

	IF ARCH_TYPE EQ ARCH_TD3300
;----------------------------------------------------------------------------;
; Configuration for TD3300A
;
BASIC_ROM		= 	0			; disable to free code space
FDC_HLT_WAIT	=	0			; halting CPU on FDC and KB wait
FDC_IPL_SW		=	1			; Use IPL SW1 for drive count
KB_HLT_WAIT		=	0			;  seems to cause issues on TD3300A
TURBO_TYPE		=	TURBO_STD		; always use Standard
TURBO_SWITCH	=	1			; boot under hardware Turbo control
TD_WS_SETUP		=	0			; set wait state register on boot (0 ws)
TD_UPMEM		=	1			; clear and display upper memory bank
		IF TD_UPMEM EQ 1
RAM_DIGITS		=	4			; display RAM as four digits
POST_TEST_PIC_REG	=	0			; disable PIC reg test (code space)
		ENDIF

	IF ARCH_SUB_TYPE EQ ARCH_NEST
;----------------------------------------------------------------------------;
; Configuration for Juko Nest N3/D-11 chipset
;
TD_WS_SETUP		=	1			; set wait state register on boot
UNSAFE_REFRESH	=	1			; go big or go home
DRAM_REFRESH	=	655
N3_UMA		=	1			; enable UMA bank (E000) on boot
POST_CARD		=	0			; not enough code space
	ENDIF
	ENDIF

	IF ARCH_TYPE EQ ARCH_UM82
;----------------------------------------------------------------------------;
; Configuration for UM82C088
;
FDC_IPL_SW		=	1			; Use IPL SW1 for drive count
BASIC_ROM		= 	0			; disable to free code space
		IF BASIC_ROM EQ 1			; if BASIC enabled, disable
POST_TEST_PIC_REG	=	0			;  unnecessary tests to free code
POST_TEST_PIC_INT	=	0			;  space since PIC is integrated
		ENDIF
	ENDIF

	IF ARCH_TYPE EQ ARCH_FE2010
;----------------------------------------------------------------------------;
; Configuration for FE2010A
;
;BASIC_ROM		=	0			; can be disabled to free code space
FD_AUTO_DETECT	=	1			; auto-detect number of floppy drives
;FE_CPU_CFG		=	110b			; boot to 9.54 MHz, 2 RAM WS
FE_CPU_CFG		=	100b			; boot to 9.54 MHz, 4 RAM WS (safest)
;FE_CPU_CFG		=	011b			; boot to 7.15 MHz, 0 RAM WS
;FE_CPU_CFG		=	000b			; boot to 4.77 MHz, 0 RAM WS
POST_TEST_PIT_1	=	0			; FE2010A chipset cannot read timer 1
SW1_FLP		=	01b			; SW1 5/6 Max # of floppy drives (0-1)
TURBO_TYPE		=	TURBO_REV		; always use reverse
	IF BASIC_ROM EQ 1				; if BASIC enabled, PIC tests are
POST_TEST_PIC_REG =	0			;  disabled to fit available code space
POST_TEST_PIC_INT =	0			; Since PIC is integrated on FE2010A
	ENDIF						;  these tests may be unnecessary

	IF ARCH_SUB_TYPE EQ ARCH_M88
;----------------------------------------------------------------------------;
; Additional Configuration for micro_8088 / NuXT
;
UNITS_IEC		=	1			; use modern IEC size units
DRAM_REFRESH	=	0			; disable DRAM refresh (for SRAM)
RAM_PARITY		=	0			; disable memory parity check
CGA_SNOW_REMOVE	=	0			; disable snow removal
FE_CPU_CFG		=	110b			; boot to 9.54 MHz, 2 RAM WS
OEM_KB_EXT		=	0			; uses AT2XTKB keyboard interface
	ENDIF
	ENDIF

	IF ARCH_TYPE EQ ARCH_EHB
;----------------------------------------------------------------------------;
; Configuration for EMM/Homebrew
;
CGA_SNOW_REMOVE	=	0			; disable snow removal
DRAM_REFRESH	=	0			; disable refresh (no DRAM)
RAM_PARITY		=	0			; disable memory parity check
DMA_INSTALLED	=	0			; no DMA 8237A installed
;FDC_ENABLE		=	0			; disable all INT 13h floppy tests (if no DMA)
;POST_TEST_FD	=	0			; disable Seek Floppy Drives
POST_TEST_DMA	=	0			; disable DMA Register Test (no DMA)
POST_TEST_KB	=	0			; disable PKEY and PKI errors
POST_TEST_PIT_1	=	0			; disable Timer 1 Test (no DRAM)
POST_TEST_PIC_REG	=	0			; disable PIC Register Test
INIT_AT_KBC		=	1			; init AT type KB controller
SW1_VID		=	00b			; SW1 5/6 Video Type (EGA/VGA)
			IF FDC_ENABLE EQ 1
SW1_FLP		=	01b			; SW1 7/8 Max # of floppy drives (0-3)
FD_AUTO_DETECT	=	1			; auto-detect number of floppy drives
			ELSE
SW1_FLP		=	00b			; SW1 7/8 Max # of floppy drives (0-3)
			ENDIF
			IF CPU_TYPE NE CPU_V20
TURBO_TYPE		=	TURBO_NONE		; disable Turbo features
			ELSE
INIT_V40		=	1			; Init V40 config registers
			ENDIF
POST_ERR_WAIT	=	0			; 0=only warn POST errors (since DMA
							;   and FDC are optional)
INT_19_BOOT_HD	=	1			; Try IPL to floppy then HD
	ENDIF

	IF ARCH_TYPE EQ ARCH_LASER
;----------------------------------------------------------------------------;
; Configuration for VTech Laser Turbo XT
;
;BASIC_ROM		= 	0			; can be disabled to free code space
		IF BASIC_ROM EQ 1			; if BASIC enabled, disable PIC tests
POST_TEST_PIC_REG	=	0			;  to free code space since PIC is
POST_TEST_PIC_INT	=	0			;  intergrated to Gate Array A1
		ENDIF

	ENDIF

;----------------------------------------------------------------------------;
; Configuration for Book 8088
;
	IF ARCH_TYPE EQ ARCH_BOOK88
CGA_SNOW_REMOVE	=	1			; enable snow removal
DRAM_REFRESH	=	0			; disable refresh (no DRAM)
RAM_PARITY		=	0			; disable memory parity/IO check
FDC_ENABLE		=	0			; disable floppy controller
POST_TEST_FD	=	0			; disable floppy test
POST_TEST_KB	=	0			; disable PKEY and PKI errors
INT_19_BOOT_HD	=	0			; Try IPL to floppy then HD
INIT_AT_KBC		=	1			; init AT type KB controller
KB_FILTER_SC	=	1			; Filter KB make/break code >= 70h
SW1_VID		=	10b			; SW1 5/6 ON/OFF Video Type CGA 80
TURBO_TYPE		=	TURBO_NONE		; disable Turbo features
			IF FDC_ENABLE EQ 1
SW1_FLP		=	01b			; SW1 7/8 Max # of floppy drives (0-3)
FD_AUTO_DETECT	=	1			; auto-detect number of floppy drives
			ELSE
SW1_FLP		=	00b			; SW1 7/8 Max # of floppy drives (0-3)
			ENDIF
;POST_ERR_WAIT	=	0			; only warn POST errors
	ENDIF

;----------------------------------------------------------------------------;
; Configuration for Compaq XT (incomplete)
;
	IF ARCH_TYPE EQ ARCH_CPQ
TURBO_TYPE		=	TURBO_NONE		; disable Turbo features
SW1_VID		=	10b			; SW1 5/6 ON/OFF Video Type CGA 80
SW1_FLP		=	1			; SW1 7/8 Max # of floppy drives (0-3)
							;  0-based: 0=1 drive, 1=2 drives, etc
	ENDIF

	IF ARCH_TYPE EQ ARCH_EMU
;----------------------------------------------------------------------------;
; Configuration for 86Box/Emulators
;
CGA_SNOW_REMOVE	=	0			; disable CGA snow removal
DRAM_REFRESH	=	0			; disable DRAM refresh
POST_TEST_CHK_ROM	=	0			; disable Checksum ROM
POST_TEST_DMA	=	0			; disable DMA Register Test
POST_TEST_PIC_INT	=	0			; disable PIC Interrupt Test
POST_TEST_PIC_REG	=	0			; disable PIC Register Test
POST_TEST_PIT_1	=	0			; disable Timer Channel 1 Test
POST_TEST_FD	=	0			; disable Floppy Drive Seek Test
							; disable Floppy Head Settle Delay
RAM_TEST_LONG	=	0			; disable long RAM test
RAM_PARITY		=	0			; disable memory parity/IO check

TURBO_TYPE		=	TURBO_NONE		; disable Turbo features
MAX_RAM_AUTO	=	1			; select max RAM from video switch

	IF ARCH_SUB_TYPE EQ ARCH_MIST
;----------------------------------------------------------------------------;
; Additional Configuration for PCXT_MiSTer
;
TURBO_TYPE		=	TURBO_STD		; enable Turbo features
;FDC_ENABLE		=	0			; disable all INT 13h floppy tests
	ENDIF
	ENDIF

	IF ARCH_SUB_TYPE EQ ARCH_MARTY
;----------------------------------------------------------------------------;
; Additional Configuration for MartyPC emulator
;
MAX_RAM 		=	MAX_RAM_CGA		; 736 KB Max detectable low RAM
MAX_RAM_AUTO	=	1			; select max RAM from video switch
CASSETTE		=	0			; use all features on 5150
CGA_SNOW_REMOVE	=	0			; disable CGA snow removal
RAM_TEST_LONG	=	0			; disable long RAM test
OEM_FONT		=	1			; use OEM style font
		IF ARCH_TYPE EQ ARCH_TURBO
TURBO_TYPE		=	TURBO_STD		; use high = turbo
		ENDIF
		IF MAX_RAM_AUTO EQ 1		; select max RAM from video switch
POST_TEST_PIT_1	=	00			; disable to free code space
		ENDIF
	ENDIF

	IF ARCH_SUB_TYPE EQ ARCH_VIRTUALXT
;----------------------------------------------------------------------------;
; Configuration for the VirtualXT emulator
;
TURBO_TYPE		=	TURBO_STD		; standard PPI 61h (1=turbo, 0=normal)
MAX_RAM 		=	MAX_RAM_CGA		; 736 KB Max detectable low RAM
MAX_RAM_AUTO	=	1			; select max RAM from video switch
CGA_SNOW_REMOVE	=	0			; disable CGA snow removal
RAM_TEST_LONG	=	0			; disable long RAM test
RAM_PARITY		=	0			; disable RAM parity checking
BASIC_ROM		=	0			; BASIC ROM support at disabled
FDC_ENABLE		=	0			; disable INT 13h floppy support
	ENDIF

	IF ARCH_SUB_TYPE EQ ARCH_VEN888
;----------------------------------------------------------------------------;
; Configuration for Vendex 888-XT/PB88/Samsung Unknown
;
BASIC_ROM		=	0			; disable to free code space
TURBO_TYPE		=	TURBO_STD		; use inverse so toggle sets speed
;MAX_RAM 		=	MAX_RAM_MDA		; if using integrated MDA
	ENDIF

;----------------------------------------------------------------------------;
; Boot to normal or turbo speed (if supported)
;
IS_TURBO		=	TURBO_TYPE NE TURBO_NONE	; use for conditionals

	IF IS_TURBO
BOOT_SPEED		EQU	BOOT_TURBO
	ELSE
BOOT_SPEED		EQU	BOOT_NORMAL
	ENDIF

;----------------------------------------------------------------------------;
; Reconfigure features as needed
;----------------------------------------------------------------------------;
; If Cassette enabled, some of the following features must be disabled due to
; code space limitations.
;
	IF CASSETTE EQ 1
;----------------------------------------------------------------------------;
; One of the following features may be enabled in addition to cassette support.
;
LIGHT_PEN		=	1			; enable light pen
POST_HD_PARMS	=	0			; enable POST HD size display
POST_OPT_ROM	=	0			; enable POST option ROM display
RANDOM_TAGLINE	=	0			; enable random tagline
	ENDIF

	IF POST_HD_CHECK EQ 0
POST_HD_PARMS	=	0			; disable HD PARM display also
	ENDIF

	IF WARM_ENABLE EQ 0
POST_WARM_COLD	=	0			; disable show boot WARM or COLD
	ENDIF

	IF FDC_ENABLE EQ 0
POST_TEST_SEEK	=	0			; remove test seek code if no floppy
	ENDIF

	IF DRAM_REFRESH NE 18			; if not standard DRAM refresh divisor
POST_TEST_DMA_TC0	=	0			; disable DMA TC0 test
	ENDIF

;----------------------------------------------------------------------------;
; Secret Menu
;
POST_QUIET		=	0			; Quiet POST, show only memory test
	IF POST_QUIET EQ 1
POST_CONFIG		=	0			; hide CPU, FPU and ports on POST
POST_FD_COUNT	=	0			; hide floppy drive count on POST
POST_HD_COUNT	=	0			; hide hard drive parameters on POST
POST_OPT_ROM	=	0			; hide option ROM loading
POST_VIDEO_TYPE	=	0			; hide the video adapter type on POST
POST_WARM_COLD	=	0			; hide boot WARM or COLD
POST_CLS		=	1			; clear screen after POST
POST_THEME		=	0			; disable all color
POST_BANNER		=	0			; hide GLaBIOS banner
	ENDIF

;----------------------------------------------------------------------------;
; Enable 186 instructions if V20
;
	IF CPU_TYPE EQ CPU_V20
.186
	ENDIF


;----------------------------------------------------------------------------;
; POST colors and visuals
;----------------------------------------------------------------------------;

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
; Pick theme from below or roll your own!
;----------------------------------------------------------------------------;
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
POST_COL_LBL_W	EQU	7			; column label width
POST_COL_PAD	EQU	4			; padding (non colored) space between cols

POST_COL_W		EQU	POST_COL_LBL_W-1	; zero-based column index

; column label width plus separator
POST_COL_VT		EQU	POST_COL_LBL_W + L_POST_L

; space between next column
POST_TAB_COL_I	EQU	POST_TAB_COL - POST_COL_LBL_W - L_POST_L - POST_COL_PAD

; prefer period-correct "KB" or IEC "KiB"
				IF UNITS_IEC EQ 1
POST_K_UNIT		EQU	<'KiB'>		; KiB size unit abbrev.
POST_M_UNIT		EQU	<'MiB'>		; MiB size
				ELSE
POST_K_UNIT		EQU	<'KB'>		; KB size unit abbrev.
POST_M_UNIT		EQU	<'MB'>		; MB size
				ENDIF

;----------------------------------------------------------------------------;
; Useful CP-437/Control Chars
;
CR 			EQU	0DH 			; Carriage return
LF 			EQU	0AH 			; Line feed
BS			EQU	08H			; Backspace ASCII
BELL			EQU	07H			; BELL ASCII
SYN			EQU	16H			; SYN C0 control char
VL			EQU	0B3H			; vertical line
HL			EQU	0C4H			; horizontal line
CURL_TOP		EQU	0F4H
CURL_BOT		EQU	0F5H
BULL			EQU	0F9H			; Bullet operator (medium centered dot)
DOT			EQU	0FAH			; Small middle dot
SQUARE		EQU	0FEH			; Black square (rectangle)
HEART			EQU	03H			; faithful companion
NOTE1			EQU	0DH
NOTE2			EQU	0EH
DBLARROW		EQU	01DH
HALF			EQU	0ABH			; 1/2
QUARTER		EQU	0ACH			; 1/4

;----------------------------------------------------------------------------;
; Beepin' Tones
; PIT delay = 315,000,000 / 264 / freq (Hz)
;----------------------------------------------------------------------------;
BEEP_C4		EQU	4561			; Middle C4 (261.626 Hz) (4560.65)
BEEP_A4		EQU	2712			; A4 (440.000 Hz)   (2711.78)
BEEP_B4		EQU	2416 			; B4 (493.883 Hz)   (2415.92)
BEEP_C5		EQU	2280			; C5 (523.251 Hz)   (2280.32)
BEEP_D5		EQU	2032			; D5 (587.329 Hz)   (2031.54)
BEEP_E5		EQU	1810			; E5 (659.255 Hz)   (1809.89)
BEEP_F5		EQU	1708			; F5 (698.456 Hz)   (1708.31)
BEEP_G5		EQU	1522			; G5 (783.991 Hz)   (1521.93)
BEEP_A5		EQU	1356			; A5 (880.000 Hz)   (1355.89)
BEEP_B5		EQU	1208			; B5 (987.766 Hz)   (1207.96)
BEEP_C6		EQU	1140			; C6 (1046.50 Hz)   (1140.16)
BEEP_1K		EQU	1193			; ~1 KHz tone       (1193.18)
BEEP_1K7		EQU	1184			; ~1007 Hz (cassette 1 bit)
BEEP_2K		EQU	BEEP_1K7 / 2	; ~2015 Hz (cassette 0 bit)

BEEP_DEFAULT	EQU	BEEP_A5		; default beep
BEEP_ERR_HIGH	EQU	BEEP_F5		; perfect fourth apart for
BEEP_ERR_LOW	EQU	BEEP_C5		;  alternating error beeps

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
INT_IMR		EQU	21H 			; Port 1 - OCW1 Interrupt Mask Register

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

; 8042 (AT) Keyboard Controller
ATKB_IO		EQU	60H			; 8042 Keyboard input/output buffer register
ATKB_CMD		EQU	64H			; 8042 Keyboard command/status register

; POST TEST card I/O
POST_CARD_PORT	EQU	80H			; can be 60H, 80H, 300H, 313H

; TD3300A (ST-xx/UNIQUE/Auva) Control Registers (90h)
TD_WS			EQU	70H			; RAM, I/O wait state control
TD_TURBO		EQU	90H			; Write 2 for Turbo, 3 for Normal
TD_MEM		EQU	0E0H			; Memory bank switch

; Nest D-11
N3_CTRL		EQU	90H			; D-11 control register
N3_MEM		EQU	0C0H			; set upper memory bank for seg E000 (A-F)

; UM82C088 Speed / Status registers
UM82_SPEED		EQU	0C0H			; write any value to toggle speed mode
UM82_STATUS		EQU	0E0H			; read memory size, speed mode

; VTech Laser Turbo XT
LASER_TURBO		EQU	1F0H			; CPU speed control port: only bit 7 used

; NMI flip/flop
NMI_R0		EQU	0A0H			; NMI Mask Register

; Joystick / Game Port
GAME_CTRL		EQU	0201H			; Game Port

; 5161 Expansion Unit Port
EXP_UNIT_CTRL	EQU	0213H			; Extender Card Control Port

; Hard Disk Controller
HDC_READ		EQU	0320H			; Read from/Write to controller
HDC_CTRL		EQU	0321H			; Read: Controller Status, Write: controller reset
HDC_PULSE		EQU	0322H			; Write: generate controller select pulse
HDC_DMA		EQU	0323H			; Write: Pattern to DMA and interrupt mask register
HDC_STAT		EQU	0324H			; disk attention/status

; Video 6845 CRT Controller
MDA_CTRL		EQU	03B8H			; MDA CRT Control Port 1
MDA_STAT		EQU	03BAH			; MDA Status Register
MDA_PEN_RST		EQU	03BBH			; CGA light pen strobe reset
CGA_IDX		EQU	03D4H			; CGA Mode Select Register
CGA_DATA		EQU	03D5H			; CGA Mode Data Register
CGA_CTRL		EQU	03D8H			; CGA Mode Control Register
CGA_COLOR		EQU	03D9H			; CGA Color Select register
CGA_STAT		EQU	03DAH			; CGA Status Register (R)
CGA_PEN_RST		EQU	03DBH			; CGA light pen strobe reset (W)

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
COM2_IIR		EQU	COM2_DATA+2		; 02FAH: Interrupt Identification Register (R)
COM3_DATA		EQU	COM2_DATA+0F0H	; 03E8H: TX/RX Buffer, Divisor LSB (RW)
COM3_IIR		EQU	COM3_DATA+2		; 03FAH: Interrupt Identification Register (R)
COM4_DATA		EQU	COM3_DATA-100H	; 02E8H: TX/RX Buffer, Divisor LSB (RW)
COM4_IIR		EQU	COM4_DATA+2		; 02EAH: Interrupt Identification Register (R)

; Parallel (LPT) ports
LPT_MDA		EQU	03BCH			; LPT1 data port (MDA)
LPT1			EQU	0378H			; LPT1 data port (I/O)
LPT2			EQU	0278H			; LPT2 data port (I/O)

; Default LPT/COM I/O timeouts (# of 64K LOOPs)
LPT_TO		EQU	20			; LPT default timeout
COM_TO		EQU	1			; COM default timeout

; V40 Control Registers
V40_WCR2		EQU	0FFF6H		; WCU Wait Cycle 2 Register
V40_WCR1		EQU	0FFF5H		; WCU Wait Cycle 1 Register

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
FDC_CMD_RTRK	EQU	00000010B		; 02H: Read Track (Diagnostic)
FDC_CMD_SPEC 	EQU	00000011B		; 03H: Specify Step & Head Load
FDC_CMD_STAT 	EQU	00000100B		; 04H: Sense Drive Status
FDC_CMD_WR		EQU	00000101B		; 05H: Write Sector
FDC_CMD_RD		EQU	00000110B		; 06H: Read Sector
FDC_CMD_RECAL	EQU	00000111B		; 07H: Recalibrate
FDC_CMD_SENSE	EQU	00001000B		; 08H: Sense Interrupt Status
FDC_CMD_WDEL	EQU	00001001B		; 09H: Write Deleted Sector
FDC_CMD_RSID	EQU	00001010B		; 0AH: Read Sector ID
FDC_CMD_RDEL	EQU	00001100B		; 0CH: Read Deleted Sector
FDC_CMD_FMT		EQU	00001101B		; 0DH: Format Track
FDC_CMD_SEEK	EQU	00001111B		; 0FH: Seek

; BDA INT 13H Status Flags 
; https://stanislavs.org/helppc/int_13-1.html
FDC_ST_OK		EQU	00H			; No error
FDC_ST_BADCMD	EQU	01H			; Bad command passed to driver
FDC_ST_ERR_MARK	EQU	02H			; Address mark not found or bad sector
FDC_ST_ERR_WP	EQU	03H			; Write Protect Error
FDC_ST_ERR_SEC	EQU	04H			; Sector not found
FDC_ST_DISK_CHG	EQU	06H			; diskette changed or removed
FDC_ST_DMA_OVR	EQU	08H			; DMA overrun
FDC_ST_DMA_64K	EQU 	09H			; DMA access across 64k boundary
FDC_ST_ERR_MED	EQU	0CH			; Invalid media type
FDC_ST_ERR_CRC	EQU	10H			; ECC/CRC error on disk read
FDC_ST_ERR_FDC	EQU	20H			; Controller error
FDC_ST_ERR_SEEK	EQU	40H			; Seek failure
FDC_ST_TIMEOUT	EQU	80H 			; Time out, drive not ready
FDC_ST_SENSE	EQU	0FFH 			; Sense operation failed

; Trivial RAM / data patterns
RAM_TEST_1		EQU 	1001010110100101B	; Simple RAM test 095A5H
RAM_TEST_2		EQU 	0111001100011101B	; Alternate RAM test 0731DH
RAM_TEST		=	RAM_TEST_2		; pick one
MAGIC_WORD		EQU	0AA55H		; Magic Word used for option ROM, IPL device

; Warm Boot Flag options set in BDA 40:72H
COLD_BOOT		EQU	0			; Cold Boot - All POST tests
WARM_BOOT		EQU	1234H			; Warm Boot - Skip some POST tests
WARM_BOOT_MEM	EQU	4321H			; Warm Boot - Preserve memory
WARM_BOOT_SUS	EQU	5678H			; Warm Boot - System suspend
WARM_BOOT_TEST	EQU	9ABCH			; Warm Boot - Manufacturer test

; Video Related
VID_DEF_COLS	EQU	80			; standard video mode columns
VID_DEF_ROWS	EQU	24			; standard video mode rows
VID_SP		EQU	' '			; fill byte for blank video RAM char


;============================================================================;
;
; 			   * * *   S T R U C T S   * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; BDA Timer Counters (6CH-70H)
;----------------------------------------------------------------------------;
TIMER_C STRUC
LW		DW	?	; 6CH  Timer Counter Low Word (ticks)
HW	  	DW	? 	; 6EH  Timer Counter High Word (hours)
OF 		DB	? 	; 70H  Timer Overflow flag
TIMER_C ENDS

;----------------------------------------------------------------------------;
; INT 1E Disk Initialization Parameter Table Vector
;
; https://stanislavs.org/helppc/dbt.html
;----------------------------------------------------------------------------;
DBT	STRUC
SRT		DB	? 	; 00 step-rate time SRT (0CH), head unload time HUT (0FH)
HLT_ND	DB	? 	; 01 head load time HLT (01H), DMA mode ND (0)
FMCT		DB	? 	; 02 timer ticks to wait before disk motor shutoff
FBPS		DB	? 	; 03 bytes per sector (0=128, 1=256, 2=512, 3=1024)
SPT		DB	? 	; 04 sectors per track (last sector number)
SGAP		DB	? 	; 05 inter-block gap length/gap between sectors
LSEC		DB	? 	; 06 data length, if sector length not specified
FGAP		DB	? 	; 07 gap length between sectors for format
FFILL		DB	? 	; 08 fill byte for formatted sectors
HDST		DB	? 	; 09 head settle time in milliseconds
FMST		DB	? 	; 0A motor startup time in eighths of a second
DBT	ENDS

;----------------------------------------------------------------------------;
; FDC Command Status Bytes (FDC_LAST_ST)
;----------------------------------------------------------------------------;
FDC_CSB STRUC
SB0		DB	?	; 00 - status register 0
SB1		DB	?	; 01 - status register 1
SB2		DB	?	; 02 - status register 2
CYL		DB	?	; 03 - cylinder number
HEAD		DB	?	; 04 - head number
SEC		DB	?	; 05 - sector number
BPS		DB	?	; 06 - bytes per sector
FDC_CSB ENDS

;----------------------------------------------------------------------------;
; INT 1D Video Initialization Parameter Table Vector (CRTC)
;
; https://stanislavs.org/helppc/6845.html
;----------------------------------------------------------------------------;
CRTC	STRUC
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
CRTC	ENDS

;============================================================================;
;
; 			   * * *   R E C O R D S   * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; Define Nibbles to Byte
; Convert two nibbles to byte (big endian)
;----------------------------------------------------------------------------;
DNB	RECORD	HBN:4, LBN:4

;----------------------------------------------------------------------------;
; Define Bytes to Word
; Convert two bytes to word (big endian)
;----------------------------------------------------------------------------;
DBW	RECORD	HWB:8, LWB:8

;----------------------------------------------------------------------------;
; Convert KiB to Bytes ( K * 1024 )
;----------------------------------------------------------------------------;
KB	RECORD	KBK:6, KBS:10

;----------------------------------------------------------------------------;
; Convert KiB to Words ( K * 1024 / 2 )
;----------------------------------------------------------------------------;
KBW	RECORD	KBWK:7, KBWS:9

;----------------------------------------------------------------------------;
; Convert KiB to Paragraphs ( K * 1024 / 16 )
;----------------------------------------------------------------------------;
KBP	RECORD	KBPK:10, KBPS:6

;----------------------------------------------------------------------------;
; Convert Word to Paragraphs ( K SHL 4 )
;----------------------------------------------------------------------------;
KP	RECORD	KPWP:12, KPWPX:4

;----------------------------------------------------------------------------;
; Convert KiB to Option ROM blocks (512 bytes) ( K * 2 )
;----------------------------------------------------------------------------;
KRB	RECORD	KRBK:15, KRBX:1

;----------------------------------------------------------------------------;
; Convert KiB in ROM blocks (512 bytes) to KB in paragraph ( K SHL 5 )
;----------------------------------------------------------------------------;
KRBP	RECORD	RB_P:11, KRBPX:5

;----------------------------------------------------------------------------;
; x86 EFLAGS
;----------------------------------------------------------------------------;
EFLAGS86	RECORD FSF:1,FZF:1,FR1:1,FAF:1,FR2:1,FPF:1,FR3:1=1,FCF:1

;----------------------------------------------------------------------------;
; BDA Equipment Flags (40:10H)
;----------------------------------------------------------------------------;
; 00      |			- LPT : # of LPT ports
;   x     |			- X1  :  unused, PS/2 internal modem
;    0    |			- GAM : Game port present
;     000 |			- COM : # of COM ports present
;        0| 		- DMA : DMA (should always be 0)
;         |00	 	- FLP : Floppy drives present (+1) (0=1 drive,1=2,etc)
;         |  00		- VID : Video mode (00=EGA/VGA, 01=CGA 40x25,
; 				-	10=CGA 80x25, 11=MDA 80x25)
;         |    11 	- MBRAM: MB RAM (00=64K, 01=128K, 10=192K, 11=256K+)
;         |      0	- FPU : FPU installed
;         |       1	- IPL : Floppy drive(s) installed (always 1 on 5160)
;----------------------------------------------------------------------------;
				IF FDC_ENABLE EQ 1
EQFLAGS RECORD	LPT:2,X1:1,GAM:1,COM:3,DMA:1,FLP:2,VID:2,MBRAM:2=11b,FPU:1,IPL:1=1
				ELSE
EQFLAGS RECORD	LPT:2,X1:1,GAM:1,COM:3,DMA:1,FLP:2,VID:2,MBRAM:2=11b,FPU:1,IPL:1=0
				ENDIF

;----------------------------------------------------------------------------;
; Video Card (VID) DIP switch settings (bits 4-5)
;
VID_ROM	EQU	00b		; OFF/OFF:	EGA/VGA/Option ROM
VID_CGA40	EQU	01b		; OFF/ON:	CGA 40 column
VID_CGA80	EQU	10b		; ON/OFF:	CGA 80 column
VID_MDA	EQU	11b		; ON/ON:	MDA

;----------------------------------------------------------------------------;
; GLaBIOS Equipment Flags (40:12H)
;----------------------------------------------------------------------------;
; 76543210
; xxxx    |			- TBD		Reserved
;     x   |			- TURBO	Turbo supported
;      x  |			- V20		1 if V20, 0 if 8088
;       xx|			- TBD		Reserved
; 84218421
;----------------------------------------------------------------------------;
GFLAGS RECORD	GTBD1:4,TURBO:1,V20:1,GTBD2:2

;----------------------------------------------------------------------------;
; POST status flags are stored in BP
;----------------------------------------------------------------------------;
; BP:
; 76543210
; x 	    |			- WARM  	Warm Boot flag
;  x 	    |			- PKI   	POST Keyboard Interrupt Received
;   x     |			- PKEY  	Keyboard key stuck
;    x    |			- PFDC  	FDC init failure
;     x   |			- PFSK  	FDC seek test failure
;      x  |			- PDMA  	DMA error
;       x |			- PMEM  	Memory Error
;        x|			- PFXX  	Reserved (do not use)
;         |xxxxxx		- TBD
;         |      xx	- GRND	Random number for tagline
; 84218421
;----------------------------------------------------------------------------;
PFLAGS RECORD WARM:1,PKI:1,PKEY:1,PFDC:1,PFSK:1,PDMA:1,PMEM:1,PFXX:1,PTBD:6,GRND:2

;----------------------------------------------------------------------------;
; BDA Keyboard Flags
;----------------------------------------------------------------------------;
; 40:17	Keyboard Flags Byte 1 (Low)
;----------------------------------------------------------------------------;
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
;----------------------------------------------------------------------------;
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
; BDA Keyboard Flags - Enhanced
;----------------------------------------------------------------------------;
; 40:96	Keyboard mode/type
;----------------------------------------------------------------------------;
;          84218421
; 	    |7 	    	- KERD	read ID in process
; 	    | 6 	    	- KEFI	last char was first ID char
; 	    |  5	    	- KENL	force num-lock if Rd ID & KBX
; 	    |   4    	- KEEN	101/102 enhanced keyboard installed
; 	    |    3   	- KERA	right ALT key depressed
; 	    |     2  	- KERC	right CTRL key depressed
; 	    |      1 	- KEE0	last code was the E0 hidden code
; 	    |       0	- KEE1	last code was the E1 hidden code
;----------------------------------------------------------------------------;
KBFLAGS3 RECORD	KERD:1,KEFI:1,KENL:1,KEEN:1,KERA:1,KERC:1,KEE0:1,KEE1:1

;----------------------------------------------------------------------------;
; 40:97	Keyboard LED flags
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- KLTE	keyboard transmit error flag
;  6 	    |			- KLMU	mode indicator update
;   5	    |			- KLRF	re-send received flag
;    4    |			- KLAK	ACK received
;     3   |			- KLCI	circus system indicator
;      2  |			- KLCL	caps-lock indicator
;       1 |			- KLNL	num-lock indicator
;        0|			- KLSL	scroll lock indicator
;----------------------------------------------------------------------------;
KBFLAGS4 RECORD	KLTE:1,KLMU:1,KLRF:1,KLAK:1,KLCI:1,KLCL:1,KLNL:1,KLSL:1

;----------------------------------------------------------------------------;
; 40:71	BIOS Keyboard Break (BIOS_BREAK)
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- KBRK	1=break active
;  654321 |			- KBRX	unused
;----------------------------------------------------------------------------;
KBBRK	RECORD	KBRK:1,KBRX:7

;----------------------------------------------------------------------------;
; FDC BDA Status Flags
;----------------------------------------------------------------------------;
; 40:3E	FD_CAL_ST	Drive recalibration status flags
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- FWIF	1=working interrupt flag
;  654    |			- FSTBD	unused
;     3   |			- FCAL3	1=recalibrate drive 3
;      2  |			- FCAL2	1=recalibrate drive 2
;       1 |			- FCAL1	1=recalibrate drive 1
;        0|			- FCAL0	1=recalibrate drive 0
;----------------------------------------------------------------------------;
FDC_SF RECORD	FWIF:1,FSTBD:3,FCAL3:1,FCAL2:1,FCAL1:1,FCAL0:1

;----------------------------------------------------------------------------;
; 40:3F	FD_MOTOR_ST	Diskette motor status flags
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- FWRT	1=write operation
;  654    |			- FMTBD	unused
;     3210|			- FMOT	drives 0-3 motor-on bitfield
;----------------------------------------------------------------------------;
FDC_MF RECORD	FWRT:1,FMTBD:3,FMOT:4

;----------------------------------------------------------------------------;
; 40:3F	FD_MOTOR_ST	Diskette motor status flags - separated drives
;----------------------------------------------------------------------------;
; 84218421
; 7654    |			- FMOTX	unused
;     3   |			- FMOT3	1=drive 3 on
;      2  |			- FMOT2	1=drive 2 on
;       1 |			- FMOT1	1=drive 1 on
;        0|			- FMOT0	1=drive 0 on
;----------------------------------------------------------------------------;
FDC_MFD RECORD	FMOTX:4,FMOT3:1,FMOT2:1,FMOT1:1,FMOT0:1

;----------------------------------------------------------------------------;
; 40:8F	FD_MODE	Floppy drive mode
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
;----------------------------------------------------------------------------;
FDC_MODE RECORD	FM1X:1,FM1D:1,FM1M:1,FM18:1,FM0X:1,FM0D:1,FM0M:1,FM08:1

;----------------------------------------------------------------------------;
; 40:90H-93H	Floppy drive media state (drives 0-3)
;----------------------------------------------------------------------------;
; 84218421
; 76      |			- FSR		data xfr rate in Kb/s (0=500,1=300,2=250)
;   5     |			- FDDS	1=dub step required
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
; FDC Digital Output Register at 3F2h (write only)
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- FDMD	1 = turn floppy drive D motor on
;  6      |			- FDMC	1 = turn floppy drive C motor on
;   5     |			- FDMB	1 = turn floppy drive B motor on
;    4    |			- FDMA	1 = turn floppy drive A motor on
;     3   |			- FDDMA	1 = DMA & I/O interface enabled
;      2  |			- FDCEN	1 = FDC enable, 0 = hold FDC at reset
;       10|			- FDDRV	floppy drive select (0=A, 1=B, 2=C, 3=D)
;----------------------------------------------------------------------------;
FDC_DOR RECORD	FDMD:1,FDMC:1,FDMB:1,FDMA:1,FDDMA:1,FDCEN:1,FDSEL:2

;----------------------------------------------------------------------------;
; FDC 765 Status Flags
;----------------------------------------------------------------------------;
; FDC Main Status Register at 3F4h (read only)
; 84218421
; 7 	    |			- FDRR	data reg ready for I/O to/from CPU
;  6      |			- FIOD	I/O direction; 1=FDC to CPU; 0=CPU to FDC
;   5     |			- FDND	FDC is in non-DMA mode
;    4    |			- FDRW	FDC read or write command in progress
;     3   |			- F3SK	floppy drive 3 in seek mode/busy
;      2  |			- F2SK	floppy drive 2 in seek mode/busy
;       1 |			- F1SK	floppy drive 1 in seek mode/busy
;        0|			- F0SK	floppy drive 0 in seek mode/busy
;----------------------------------------------------------------------------;
FDC_MSR RECORD	FDRR:1,FIOD:1,FDND:1,FDRW:1,F3SK:1,F2SK:1,F1SK:1,F0SK:1

;----------------------------------------------------------------------------;
; FDC Command Status Register 0 at 3F5h
;----------------------------------------------------------------------------;
; 84218421
; 76	    |			- ST0CS	last command status (see below)
;   5     |			- ST0SK	set to 1 when FDD completes a seek command
;    4    |			- ST0CHK	equipment check (see note)
;     3   |			- ST0NR	not ready on read/write or SS access to head 1
;      2  |			- ST0HD	head number at interrupt (head 0 or 1)
;       10|			- ST0DRV	unit selected at interrupt (0=A, 1=B, 2=...)
;----------------------------------------------------------------------------;
; Bits
;	 76  Last Command Status
;	 00  command terminated successfully
;	 01  command execution started but terminated abnormally
;	 10  invalid command issued
;	 11  command terminated abnormally due to a change in state of
;	     the Ready Signal from the FDC  (reserved on PS/2)
;
;	- equipment check can occur if FDD signals a fault or track zero is
;	  not found after 77 steps on a recalibrate command
;----------------------------------------------------------------------------;
FDC_ST0 RECORD	ST0CS:2,ST0SK:1,ST0CHK:1,ST0NR:1,ST0HD:1,ST0DRV:2

;----------------------------------------------------------------------------;
; FDC Command Byte 0
;----------------------------------------------------------------------------;
; 84218421
; 7       |			- FC0MT	MT = Multi-Track
;  6      |			- FC0MF	MF = MFM mode
;   5     |			- FC0SK	SK = SKip Deleted-data address mark
;    43210|			- FC0CMD	FDC command number
;----------------------------------------------------------------------------;
FDC_CB RECORD	FC0MT:1,FC0MF:1=1,FC0SK:1,FC0CMD:5

;----------------------------------------------------------------------------;
; FDC Command Byte 1
;----------------------------------------------------------------------------;
; 84218421
; 76543   |			- FC1X	unused
;      2  |			- FC1HD	head (0-1)
;       10|			- FC1DS	drive (0-3)
;----------------------------------------------------------------------------;
FDC_CB1 RECORD	FC1X:5,FC1HD:1,FC1DS:2

;----------------------------------------------------------------------------;
; Port 3BD Printer Status Flags returned from INT 17
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- LPBZ	not busy (note: 0 means busy)
;  6      |			- LPACK	acknowledge (printer is attached)
;   5     |			- LPOP	20H out of paper
;    4    |			- LPSEL	10H selected (0 means off-line)
;     3   |			- LPIO	08H I/O error
;      21 |			- LPX		06H unused
;        0|			- LPTO	01H time-out error
;----------------------------------------------------------------------------;
PRN_STAT RECORD	LPBZ:1,LPACK:1,LPOP:1,LPSEL:1,LPIO:1,LPX:2,LPTO:1

;----------------------------------------------------------------------------;
; Port 3BE printer control register   (Parallel Printer Port)
;----------------------------------------------------------------------------;
; 84218421
; 765	    |			- LCX		unused
;    4    |			- LCIRQ	0 = IRQ disable, 1=IRQ enable for ACK
;     3   |			- LCDR	1 = printer reads output,  (pin 17)
;      2  |			- LCINI	0 = initialize printer,  (pin 16)
;       1 |			- LCLF	1 = auto line feed,  (pin 14)
;        0|			- LCOUT	1 = output data to printer,  (pin 1)
;----------------------------------------------------------------------------;
PRN_CTRL RECORD	LCX:3,LCIRQ:1,LCDR:1,LCINI:1,LCLF:1,LCOUT:1

;----------------------------------------------------------------------------;
; Port 3FB - Line Control Register - LCR (read/write)
;----------------------------------------------------------------------------;
; 84218421
; 7	    |			- DLAB	1 = baud rate divisor (DLAB)
;  6      |			- LCBK	0 = turn break off, 1 = force spacing break state
;   5     |			- LCPD	0 = parity disabled, 1 = enabled
;    4    |			- LCEPS	0 = odd parity, 1 = even (EPS)
;     3   |			- LCPEN	0 = no parity, 1 = parity (PEN)
;      2  |			- LCSB	0 = 1 stop bit, 1 = 1.5 or 2
;       10|			- LCWLS	word length select bits
;----------------------------------------------------------------------------;
COM_LCR RECORD	DLAB:1,LCBK:1,LCPD:1,LCEPS:1,LCPEN:1,LCSB:1,LCWLS:2

;----------------------------------------------------------------------------;
; Port 3FC - Modem Control Register - MCR (read/write)
;----------------------------------------------------------------------------;
; 84218421
; 765	    |			- MCRX	unused
;    4    |			- MCLB	0 = normal, 1 = loop back test
;     3   |			- MCO2	OUT2
;      2  |			- MCO1	OUT1
;       1 |			- RTS		1 = activate RTS
;        0|			- DTR		1 = activate DTR
;----------------------------------------------------------------------------;
COM_MCR RECORD	MCRX:3,MCLB:1,MCO2:1,MCO1:1,RTS:1,DTR:1

;----------------------------------------------------------------------------;
; Port 3FE - Modem Status Register - MSR (read only)
;----------------------------------------------------------------------------;
; 84218421
; 7	    |			- MLSD	1 = receive line signal detect
;  6      |			- MRI		1 = ring indicator (RI)
;   5     |			- MDSR	1 = DSR
;    4    |			- MCTS	1 = CTS
;     3   |			- DDCD	1 = DDCD Delta Data Carrier Detect (DCD changed)
;      2  |			- DRI		1 = RI ring indicator changed
;       1 |			- DDSR	1 = DDSR Delta DSR (DSR changed)
;        0|			- DCTS	1 = DCTS Delta CTS (CTS changed)
;----------------------------------------------------------------------------;
COM_MSR RECORD	MLSD:1,MRI:1,MDSR:1,MCTS:1,DDCD:1,DRI:1,DDSR:1,DCTS:1

;----------------------------------------------------------------------------;
; Port 3FD/2FD - Line Status Register - LSR (read only)
;----------------------------------------------------------------------------;
; 84218421
; 7	    |			- LSX		unused
;  6      |			- TSRE	1 = transmitter shift register empty (TSRE)
;   5     |			- THRE	1 = transmitter holding register empty (THRE)
;    4    |			- LBI		1 = break interrupt  (BI)
;     3   |			- LFE		1 = framing error (FE)
;      2  |			- LPE		1 = parity error (PE)
;       1 |			- LOE		1 = overrun error (OE)
;        0|			- LDR		1 = data ready
;----------------------------------------------------------------------------;
COM_LSR RECORD	LSX:1,TSRE:1,THRE:1,LBI:1,LFE:1,LPE:1,LOE:1,LDR:1

;----------------------------------------------------------------------------;
; HALT_BEEP Pattern - Short / Long
;----------------------------------------------------------------------------;
BEEP_SL RECORD	BEEP_S:4, BEEP_L: 4

;----------------------------------------------------------------------------;
; PIT Timer CW
;----------------------------------------------------------------------------;
; Control Word Counter 1 (port 43H) - System Timer:
;  01 		- SC: Select Counter 1
;    11		- RW: Read/Write 2xR/2xW
;      010		- M:  Mode 2, Rate Gen
;         0		- BCD: 0
;----------------------------------------------------------------------------;
PIT_CW RECORD	PCWSC:2, PCWRW:2, PCWM:3, PCWBCD:1

;----------------------------------------------------------------------------;
; DMA Mode Register
;----------------------------------------------------------------------------;
; 01 			; Mode 1 (Single)
;   0 		; INC: address decrement
;    1 		; Auto-initialization
;     10 		; Operation: Read from memory
;       00 		; Channel 0
;----------------------------------------------------------------------------;
DMA_MR RECORD	DMM:2=01B, DMINC:1, DMAI:1=1, DMOP:2, DMCH:2

;----------------------------------------------------------------------------;
; 8237 DMA Command Register
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |		- DACK	1 = DACK sense active high, 0 = low
;  6      |		- DREQ	1 = DREQ sense active high, 0 = low
;   5     |		- DWS		1 = Extended write selection, 0 = Late write
;    4    |		- DPRI	1 = Rotating priority, 0 = Fixed priority
;     3   |		- DTIM	1 = Compressed timing, 0 = Normal timing
;      2  |		- DDIS	1 = Controller disable, 0 = Controller enable
;       1 |		- DHLD	1 = Channel 0 address hold enable, 0 = disable
;        0|		- DM2M	1 = Memory-to-memory enable, 0 = disable
;----------------------------------------------------------------------------;
DMA_CR RECORD	DACK:1,DREQ:1,DWS:1,DPRI:1,DTIM:1,DDIS:1,DHLD:1,DM2M:1

;----------------------------------------------------------------------------;
; 8237 DMA Status Register
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |		- CR3		1 = Channel 3 request
;  6      |		- CR2		1 = Channel 2 request
;   5     |		- CR1		1 = Channel 1 request
;    4    |		- CR0		1 = Channel 0 request
;     3   |		- TC3		1 = Channel 3 has reached TC
;      2  |		- TC2		1 = Channel 2 has reached TC
;       1 |		- TC1		1 = Channel 1 has reached TC
;        0|		- TC0		1 = Channel 0 has reached TC
;----------------------------------------------------------------------------;
DMA_SR RECORD	CR3:1,CR2:1,CR1:1,CR0:1,TC3:1,TC2:1,TC1:1,TC0:1

;----------------------------------------------------------------------------;
; 8237 DMA Single Channel Mask Register
;----------------------------------------------------------------------------;
; 84218421
;      2  |		- SMCLR	1 = Set mask bit, 0 = Clear mask bit
;       10|		- SMCH	Select channel mask bit (0-3)
;----------------------------------------------------------------------------;
DMA_SMR RECORD	SMCLR:6,SMCH:2

;----------------------------------------------------------------------------;
; PIC Control Registers
;----------------------------------------------------------------------------;
; ICW1:
;  000 		- A7-A5: unused on 8086 mode
;     1 		- D4:   1 = ICW1 (and Port 0)
;      0 		- LTIM: 0 = Edge Triggered Mode (low to high TTL transition)
;       0 		- ADI:  0 = Call Address Interval of 8
;        1 		- SNGL: 1 = Single mode (no cascading PICs or ICW3)
;         1		- IC4:  1 = ICW4 Needed
;----------------------------------------------------------------------------;
ICW1	RECORD	D4:4=1, LTIM:1, ADI:1, SNGL:1=1, IC4:1=1

; ICW2:
;  00001 		- T7-T3: Interrupt Vector Address:
;				INT = INT | 8 -> IRQ 0-7 to CPU INT 8-15
;       000 	- D2-D0: unused on 8086 mode
;----------------------------------------------------------------------------;
ICW2	RECORD	ICW2IVA:5, ICW2X:3=0

; ICW4:
;  000 		- D7-D5: unused
;     0		- SFNM: 0 = Not Special Fully Nested Mode
;      10		- BUF:  2 = Buffered Mode/Slave
;        0		- AEOI: 0 = normal EOI
;         1		- uPM:  1 = 8086 system
;----------------------------------------------------------------------------;
ICW4	RECORD	SFNM:4=0, ICWBUF:2, AEOI:1, uPM:1

;----------------------------------------------------------------------------;
; IMR / OCW1 Interrupt Mask
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |		- IRQ7	1=interrupt masked (disabled), 0=not masked
;  6      |		- IRQ6
;   5     |		- IRQ5
;    4    |		- IRQ4
;     3   |		- IRQ3
;      2  |		- IRQ2
;       1 |		- IRQ1
;        0|		- IRQ0
;----------------------------------------------------------------------------;
OCW1	RECORD	IRQ7:1,IRQ6:1,IRQ5:1,IRQ4:1,IRQ3:1,IRQ2:1,IRQ1:1,IRQ0:1

;----------------------------------------------------------------------------;
; OCW2
;----------------------------------------------------------------------------;
; 84218421
; 765	    |		- O2CMD	Rotate and End of Interrupt Mode Command
;					001b = Non-Specific EOI Command (default)
;    43   |		- O2X		unused (00)
;      210|		- O2L		Interrupt level acted upon
;----------------------------------------------------------------------------;
OCW2	RECORD	O2CMD:3=001b, O2X:2, O2L:3
EOI	EQU		OCW2 <>		; Non-Specific EOI

;----------------------------------------------------------------------------;
; OCW3
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |		- O3D7	unused (0)
;  65     |		- ESMM/SMM	Enable/special mask mode
;    43   |		- O3D3	unused (01b)
;      2  |		- O3P		1=Poll command, 0=No Poll command
;       10|		- O3RR	Read Register command
;----------------------------------------------------------------------------;
OCW3	RECORD	O3D7:1, ESMM:2, O3D3:2=1, O3P:1, O3RR:2

;----------------------------------------------------------------------------;
; NMI Mask Register
;----------------------------------------------------------------------------;
; 84218421
; x 	    |		- NMIE	1=enable NMI, 0=disable
;  0000000|		- NMIX	unused (0)
;----------------------------------------------------------------------------;
NMI	RECORD	NMIE:1, NMIX:7

;----------------------------------------------------------------------------;
; V40 WCY1
;----------------------------------------------------------------------------;
; 84218421
; 76 	    |		- IOW		I/O Wait States (0-3)
;   54    |		- UMW		Upper Memory Block Wait States (0-3)
;     32  |		- MMW		Middle Memory Block Wait States (0-3)
;       10|		- LMW		Lower Memory Block Wait States (0-3)
;----------------------------------------------------------------------------;
V40_WCY1	RECORD	IOW:2, UMW:2, MMW:2, LMW:2

;----------------------------------------------------------------------------;
; 6845 Video - Port 3DA Status Register
;----------------------------------------------------------------------------;
; 84218421
; 7654    |			- VSX		unused
;     3   |			- VSVS	vertical retrace, RAM access OK (next 1.25ms)
;      2  |			- VSPE	0 = light pen on, 1 = light pen off
;       1 |			- VSPT	light pen trigger set
;        0|			- VSHS	horiz or vert retrace, RAM access OK
;----------------------------------------------------------------------------;
VID_STAT	RECORD	VSX:4, VSVS:1, VSPE:1, VSPT:1, VSHS:1

;----------------------------------------------------------------------------;
; 6845 Video - 3D9 Color Select Register (Text)
;----------------------------------------------------------------------------;
; 84218421
; 765     |			- CTX		unused
;    4    |			- CTBI	background intensity
;     3   |			- CTIN	select intensity setting
;      210|			- CTBC	screen/border RGB
;----------------------------------------------------------------------------;
VID_CSTXT	RECORD	CTX:3=001B, CTBI:1=1B, CTIN:1, CTBC:3

;----------------------------------------------------------------------------;
; 6845 Video - 3D9 Color Select Register (Graphics)
;----------------------------------------------------------------------------;
; 84218421
; 76      |			- CGPH	palette high bits (unused)
;   5     |			- CGPL	1 = palette 1, 0=palette 0
;    4    |			- CGX		unused
;     3   |			- CGIN	intensity
;      210|			- CGBG	RGB for background
;----------------------------------------------------------------------------;
VID_CSGFX	RECORD	CGPH:2,CGPL:1=1B,CGX:1=1B,CGIN:1=1B,CGBG:3=111B

;----------------------------------------------------------------------------;
; Default video mem attribute byte to fill memory on clear
;----------------------------------------------------------------------------;
; 84218421
; 7654    |			- VBG		background color (0-15) default black
;     3210|			- VFB		foreground color (0-15) default gray
;----------------------------------------------------------------------------;
VID_ATTR	RECORD	VBG:4=BLACK,VFB:4=GRAY

;----------------------------------------------------------------------------;
; MDA Character Attributes
;----------------------------------------------------------------------------;
; 84218421
; 7       |			- MDBK	1 = blink, 0 = no blink
;  654    |			- MDBG	000b = normal, 111b = Reverse
;     3   |			- MDIN	0 = normal, 1 = bold
;      210|			- MDFG	111 = normal, 001 = underline, 000 = none
;----------------------------------------------------------------------------;
MDA_CH_ATTR	RECORD	MDBK:1,MDBG:3,MDIN:1,MDFG:3=111B

;----------------------------------------------------------------------------;
; 8255 PPI Channel Control Register Byte (Port 63h) Flags
;----------------------------------------------------------------------------;
; Normal operation: Mode 0, Ports A,C (U and L) as INPUT, Port B as OUTPUT
; 84218421
; 1 	    |			- PPEN	1=Active
;  00     |			- PPAM	Port A Mode: (0 default)
;    1    |			- PPAD	Port A Dir: 0=output, 1=input (default)
;     1   |			- PPCU	Port C (Upper): 0=output, 1=input (default)
;      0  | 		- PPBM	Port B Mode: (0 default)
;       0 | 		- PPBD	Port B Dir: 0=output (default), 1=input
;        1|			- PPCL	Port C (Lower): 0=output, 1=input (default)
;----------------------------------------------------------------------------;
PPI_CR RECORD	PPEN:1=1,PPAM:2=00b,PPAD:1=1,PPCU:1=1,PPBM:1,PPBD:1,PPCL:1=1

			IF ARCH_TYPE EQ ARCH_TD3300
;----------------------------------------------------------------------------;
; TD3300A/D-11 Wait State Config Register (70H)
;----------------------------------------------------------------------------;
; 84218421
; 76 	    |			- TDWSI	Slot I/O  (# of wait states 0-3)
;   54    |			- TDWSR	Slot RAM  (# of wait states 0-3)
;     32  |			- TDWIO	Board I/O (# of wait states 0-3)
;       1 |			- TDWRA	Board RAM (# of wait states 0-1)
;        0| 		- TDWRO	Board ROM (# of wait states 0-1)
;----------------------------------------------------------------------------;
TD_WS_CR	RECORD	TDWSI:2=3,TDWSR:2=3,TDWIO:2=1,TDWRA:1=0,TDWRO:1=1

TD_WS_R_1	EQU	TD_WS_CR <>				; TD1 - default power on state
TD_WS_R_2	EQU	TD_WS_CR < 2, 1, 0, 0, 1 >	; TD2 - faster
TD_WS_R_3	EQU	TD_WS_CR < 0, 1, 0, 0, 0 >	; TD3 - even faster
TD_WS_R_4	EQU	TD_WS_CR < 0, 0, 0, 0, 0 >	; TD4 - fastest (0 ws all)

;----------------------------------------------------------------------------;
; If TD_WS_SETUP=1, set below wait state register configuration on boot.
; The Nest/D-11 seems to have issues when I/O WS is set to 1 reading from a
; port address not present that is seemingly related to the number of cards
; installed, which can lead to misdetection of interfaces. So the I/O WS
; is set to 2 during POST and then to 1 for BOOT.
;
			IF ARCH_SUB_TYPE EQ ARCH_NEST
TD_WS_R	EQU	TD_WS_R_2		; POST: 2 I/O slot ws, 1 I/O RAM ws, 1 board WS
TD_WS_RB	EQU	TD_WS_R_3		; BOOT: 1 I/O slot ws, 0 I/O RAM ws, 0 board WS
			ELSE
;TD_WS_R	EQU	TD_WS_R_1		; default power on
TD_WS_R	EQU	TD_WS_R_3		; 0 I/O slot ws, 1 I/O RAM ws, 0 board WS
			ENDIF

;----------------------------------------------------------------------------;
; TD3300A Speed (Turbo/Normal) Register (90H)
;----------------------------------------------------------------------------;
; 765432  |			- TDSX	Unused
;       1 |			- TDSH	0=use hardware switch, 1=use bit 0 (TDSS)
;        0| 		- TDSS	if TDSH=1: 1=4.77, 0=turbo
;----------------------------------------------------------------------------;
			IF TURBO_SWITCH EQ 1
TD_TURBO_CR	RECORD	TDSX:6,TDSH:1=0,TDSS:1	; hardware switch enabled
			ELSE
TD_TURBO_CR	RECORD	TDSX:6,TDSH:1=1,TDSS:1	; hardware switch disabled
			ENDIF

;----------------------------------------------------------------------------;
; TD3300A Upper Memory bank switch Register (E0H)
;----------------------------------------------------------------------------;
; 7654321 |			- TDUX	Unused
;        0| 		- TDUB	map 2000H-8000H: 0=lower bank,1=upper bank
;----------------------------------------------------------------------------;
TD_MEM_CR	RECORD	TDUX:7,TDUB:1

;----------------------------------------------------------------------------;
; D-11 (Nest N3) Control Register (90H)
; Not confirmed to be accurate!
;----------------------------------------------------------------------------;
; 76      |    - D11UM    11=enable UMA/EMS bank switching by 0C0H (0AH-0FH)
;   5     |    - D11X     Unused?
;    4    |    - D11SX    Select xtal (1=high speed, 0=low)
;     3   |    - D11Y     Unused?
;      2  |    - D11SC    Clock multiplier 1=2x (low xlat+med), 0=1x
;       1 |    - D11SF    Speed flag (read/writeable)
;        0|    - D11SS    R: state of HW switch W: 1=low osc, 0=high osc
;----------------------------------------------------------------------------;
D11_CR	RECORD	D11UM:2,D11X:1,D11SX:1,D11B:1,D11SC:1,D11SF:1,D11SS:1

			ENDIF		; END ARCH_TYPE EQ ARCH_TD3300

			IF ARCH_TYPE EQ ARCH_UM82
;----------------------------------------------------------------------------;
; UM82C088 Status Register (E0H)
;----------------------------------------------------------------------------;
; 7       |			- U8SPD	Speed: 0=Low, 1=High
;  6      | 		- U8X1	Unused
;   54    |			- U8MEM	11b=256K, 01b=512K, x0b=640K
;     32  |			- U8VID	Video adapter
;       10|			- U8FLP	Floppy drives
;----------------------------------------------------------------------------;
UM82_ST	RECORD	U8SPD:1,U8X1:1,U8MEM:2,U8VID:2,U8FLP:2
UM82_256K	EQU		UM82_ST <,,11b>		; 256K RAM
UM82_512K	EQU		UM82_ST <,,01b>		; 512K RAM
UM82_640K	EQU		UM82_ST <,,10b>		; 640K RAM
			ENDIF

			IF ARCH_TYPE EQ ARCH_LASER
;----------------------------------------------------------------------------;
; VTech Laser XT control register (1F0H)
;----------------------------------------------------------------------------;
; 7       |			- LASER_SPD	Speed: 0=Low, 1=High
;  654321 | 		- LASER_X1	Unused
;----------------------------------------------------------------------------;
LASER_CR	RECORD	LASER_SPD:1=1,LASER_X1:7
			ENDIF

			IF ARCH_TYPE EQ ARCH_FE2010
;----------------------------------------------------------------------------;
; FE2010A Configuration Register (Port 63h) Flags
;----------------------------------------------------------------------------;
; 84218421
; 100     |             - FSPD      CPU Clock Frequency and Wait States
;         |                               00x = 4.77, 1 IOWS, 0 MBWS *
;         |                               010 = 7.15, 4 IOWS, 2 MBWS
;         |                               011 = 7.15, 4 IOWS, 0 MBWS *
;         |                               100 = 9.54, 6 IOWS, 4 MBWS * default
;         |                               110 = 9.54, 6 IOWS, 2 MBWS
;         |                               101 = 9.54, 6 IOWS, 0 MBWS
;         |                               111 = 9.54, 6 IOWS, 0 MBWS
;    0    |             - FME1      RAM size high bit
;     0   |             - FLCK      1=lock bits 0-4 until next restart
;      0  |             - FME2      RAM size low bit
;         |                               00  = 640K
;         |                               01  = 256K
;         |                               10  = 512K
;       0 |             - FFPU      0=No FPU/NMI, 1=enable FPU/NMI
;        1|             - FPAR      0=Parity check enabled, 1=Parity disabled
;----------------------------------------------------------------------------;
				IF RAM_PARITY EQ 1
FE_CR RECORD      FSPD:3=FE_CPU_CFG,FME1:1,FLCK:1,FME2:1,FFPU:1,FPAR:1
				ELSE
FE_CR RECORD      FSPD:3=FE_CPU_CFG,FME1:1,FLCK:1,FME2:1,FFPU:1,FPAR:1=1
				ENDIF

;----------------------------------------------------------------------------;
; FE2010A: 8255 PPI Channel B (Port 61h) Flags
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PBKB	0=enable keyboard read, 1=clear
;  6      |			- PBKC	0=hold keyboard clock low, 1=enable clock
;   5     |			- PBIO	0=enable i/o check, 1=disable
;    4    |			- PBPC	0=enable memory parity check, 1=disable
;     3   |			- PBTB	0=turbo, 1=normal*
;      2  |			- PBSW	0=read SW1-4, 1=read SW-5-8*
;       1 |			- PBSP	0=turn off speaker, 1=turn on
;        0|			- PBST	0=turn off timer 2, 1=turn on
; * Note: bits 2 and 3 are reversed on FE2010A motherboards
;----------------------------------------------------------------------------;
PPI_B_F RECORD	PBKB:1,PBKC:1,PBIO:1,PBPC:1,PBTB:1,PBSW:1,PBSP:1,PBST:1

			ELSE					; NOT ARCH_FE2010
				IF ARCH_TYPE EQ ARCH_5150
;----------------------------------------------------------------------------;
; 5150: 8255 PPI Channel B (Port 61h) Flags
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PBKB	0=enable keyboard read, 1=clear
;  6      |			- PBKC	0=hold keyboard clock low, 1=enable clock
;   5     |			- PBIO	0=enable i/o check, 1=disable
;    4    |			- PBPC	0=enable memory parity check, 1=disable
;     3   |			- PBCM	0=cassette motor
;      2  |			- PBSW	0=read SW1-4, 1=read SW-5-8
;       1 |			- PBSP	0=turn off speaker, 1=turn on
;        0|			- PBST	0=turn off timer 2, 1=turn on
;----------------------------------------------------------------------------;
PPI_B_F RECORD	PBKB:1,PBKC:1,PBIO:1,PBPC:1,PBCM:1,PBSW:1,PBSP:1,PBST:1

				ELSE
;----------------------------------------------------------------------------;
; 5160/Standard: 8255 PPI Channel B (Port 61h) Flags
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
;----------------------------------------------------------------------------;
PPI_B_F RECORD	PBKB:1,PBKC:1,PBIO:1,PBPC:1,PBSW:1,PBTB:1,PBSP:1,PBST:1
				ENDIF
			ENDIF

;----------------------------------------------------------------------------;
; 5160: 8255 PPI Channel C (Port 62h) Flags
; * When PPI B PBSW = 0
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PCPE	0=no parity error, 1=memory parity error
;  6      |			- PCIE	0=no i/o channel error, 1=i/o channel error
;   5     |			- PCT2	timer 2 output / cassette data output
;    4    |			- PCCI	cassette data input
;     32  |			- PCMB	SW 3,4: MB RAM (00=64K, 01=128K, 10=192K, 11=256K)
;       1 |			- PCFP	SW 2: 0=no FPU, 1=FPU installed
;        0|			- PCFD	SW 1: Floppy drive (IPL) installed
;----------------------------------------------------------------------------;
PPI_C_X_L RECORD	PCPE:1,PCIE:1,PCT2:1,PCCI:1,PCMB:2,PCFP:1,PCFD:1

;----------------------------------------------------------------------------;
; 8255 PPI Channel C Flags (Port 62h)
; * When PPI B PBSW = 1
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- PC2PE	0=no parity error, 1 r/w memory parity check error
;  6      |			- PC2IE	0=no i/o channel error, 1 i/o channel check error
;   5     |			- PC2T2	timer 2 output
;    4    |			- PC2CI	cassette data input
;     32  |			- PCDRV	SW 7,8: # of drives (00=1, 01=2, 10=3, 11=4)
;       10|			- PCVID	SW 5,6: video Mode (00=ROM, 01=CG40, 10=CG80, 11=MDA)
;----------------------------------------------------------------------------;
PPI_C_X_H RECORD	PC2PE:1,PC2IE:1,PC2T2:1,PC2CI:1,PCDRV:2,PCVID:2

;----------------------------------------------------------------------------;
; Set up boot mode (PPI_B_BOOT) for PPI Channel B
;----------------------------------------------------------------------------;

			IF ARCH_TYPE EQ ARCH_5150
;----------------------------------------------------------------------------;
; 5150 Power-On: KB hold low+disable, NMI on, spkr data off, cass off, PIT on
;
PPI_B_BOOT	= MASK PBKB OR MASK PBIO OR MASK PBSW OR MASK PBST OR MASK PBCM

			ELSE				; ARCH_TYPE NE ARCH_5150
				IF BOOT_SPEED EQ BOOT_TURBO
;----------------------------------------------------------------------------;
; Turbo Std Power-On: KB hold low+disable, NMI on, spkr data off, turbo ON/OFF
;
PPI_B_BOOT	= MASK PBKB OR MASK PBIO OR MASK PBSW

				ELSE			; BOOT_SPEED NE BOOT_TURBO
;----------------------------------------------------------------------------;
; Default Power-On: KB hold low+disable, NMI on, spkr data off, turbo OFF/ON
;
PPI_B_BOOT	= MASK PBKB OR MASK PBIO OR MASK PBSW OR MASK PBTB

				ENDIF			; /BOOT_SPEED EQ BOOT_TURBO

				IF TURBO_TYPE EQ TURBO_REV
;----------------------------------------------------------------------------;
; Turbo Reverse Power-On: Reverse PBTB
;
PPI_B_BOOT	= PPI_B_BOOT XOR MASK PBTB
				ENDIF			; /TURBO_TYPE EQ TURBO_REV

			ENDIF				; /ARCH_TYPE EQ ARCH_5150

				IF (ARCH_TYPE EQ ARCH_EMU) AND (ARCH_SUB_TYPE EQ ARCH_MIST)
;----------------------------------------------------------------------------;
; PCXT_MiSTer XTCTL register (port 8888h)
;----------------------------------------------------------------------------;
; 84218421
; 7 	    |			- MCAT4	1=4MHz AT speed (high), 0=use MCSP speed
;  6      |			- MCA0	a000h off
;   5     |			- MCMD	MDA (Reserved)
;    4    |			- MCAD	adlib off
;     32  |			- MCSP	Speed: 01=5MHz, 10=8MHz, 11=10MHz
;         |					(with MCAT4=0)
;       1 |			- MCBR	border
;        0|			- MCCP	composite
;----------------------------------------------------------------------------;
MC_XTCTL	RECORD	MCAT4:1,MCA0:1,MCMD:1,MCAD:1,MCSP:2,MCBR:1,MCCP:1

MC_PORT	EQU	8888h			; PCXT_MiSTer control port
MCSP_AT4	EQU	1b			; AT clock speed (with MCSP_4)
MCSP_4	EQU	00b			; 4 MHz (MCSP)
MCSP_5	EQU	01b			; 5 MHz (MCSP)
MCSP_8	EQU	10b			; 8 MHz (MCSP)
MCSP_10	EQU	11b			; 10 MHz (MCSP)
MCSP_TOG	EQU	MC_XTCTL <MCSP_AT4,,,,MCSP_5>		; toggle high/low
;MCSP_HIGH	EQU	MC_XTCTL <MCSP_AT4>			; AT speed bit
MCSP_LOW	EQU	MC_XTCTL <,,,,MCSP_8 AND MCSP_10>	; clear 8/10 bit
MCSP_SPD	EQU	MASK MCAT4 OR MASK MCSP			; speed bits
				ENDIF

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
;	JMP_SHORT = force SHORT jump
;
; - SS must be CS
;----------------------------------------------------------------------------;
CALL_NS 	MACRO CALL_JMP, JMP_SHORT
		LOCAL	CALL_JMP_PTR, CALL_JMP_RET
	MOV	SP, OFFSET CALL_JMP_PTR
			IFNB <JMP_SHORT>
	JMP	SHORT CALL_JMP
			ELSE
	JMP	CALL_JMP
			ENDIF
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
			IF ARCH_TYPE NE ARCH_EMU
	JMP	SHORT _DONE
_DONE:
			ENDIF
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
			IF ARCH_TYPE NE ARCH_EMU
	XOR	CX, CX 				; delay 65535 LOOPs
	IO_DELAY
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Variable delay with slowdown for Turbo builds
;----------------------------------------------------------------------------;
; Input: CX delay in 30 clock cycle increments
;	R = additional delay factor
; Output: CX = 0
;----------------------------------------------------------------------------;
IO_DELAY_TURBO	MACRO	R
		LOCAL _DONE
_DONE:
		IF IS_TURBO
			IFNB <R>
			REPT R
	IO_DELAY_SHORT
			ENDM
			ELSE
	IO_DELAY_SHORT
			ENDIF
		ENDIF
	LOOP	_DONE					; long delay for I/O
		ENDM

;----------------------------------------------------------------------------;
; Compare an equipment flag
;----------------------------------------------------------------------------;
; Input:
;	FLAG = field name from EQUIP_FLAGS RECORD
;	FVAL = value to compare
;	SET_BDA = if defined, saves CX and sets DS = BDA
;		otherwise assumes DS = BDA and clobbers CX
; Output: AX = flag value
;
; Note: flags must not cross byte boundary (which they don't)
;----------------------------------------------------------------------------;
CMP_EFLAG	MACRO	FLAG, FVAL, SET_BDA
		LOCAL FLAG_MASK, FLAG_BIT, FLAG_MEM
			IFNB <SET_BDA>
	PUSH	CX					; save CX
	PUSH	DS
	MOV	CX, SEG _BDA			; DS = BDA
	MOV	DS, CX
			ENDIF

;----------------------------------------------------------------------------;
; Shift if flag is in high byte to low for byte operations
;
			IF FLAG LT 8		; is in low byte?
FLAG_MASK	= MASK FLAG
FLAG_BIT	= FLAG AND 0111B
FLAG_MEM	= EQUIP_FLAGS[0]			; low BDA flags byte
			ELSE				; is in high byte
FLAG_MASK	= HIGH MASK FLAG
FLAG_BIT	= (FLAG - 8) AND 0111B
FLAG_MEM	= EQUIP_FLAGS[1]			; high BDA flags byte
			ENDIF

	MOV	AL, BYTE PTR FLAG_MEM
	AND	AL, FLAG_MASK
	CMP	AL, FVAL SHL FLAG_BIT

			IFNB <SET_BDA>
	POP	DS
	POP	CX
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Get an equipment flag
;----------------------------------------------------------------------------;
; Input:
;	FLAG = field name from EQUIP_FLAGS RECORD
;	SET_BDA = if defined, saves CX and sets DS = BDA
;		otherwise assumes DS = BDA and clobbers CX if 3 or 4 shifts
; Output: AX = flag value
;
; Note: flags must not cross byte boundary (which they don't)
;----------------------------------------------------------------------------;
GET_EFLAG	MACRO	FLAG, SET_BDA
		LOCAL FLAG_MASK, FLAG_BIT, FLAG_MEM
			IFNB <SET_BDA>
	PUSH	CX					; save CX
	PUSH	DS
	MOV	CX, SEG _BDA			; DS = BDA
	MOV	DS, CX
			ENDIF

;----------------------------------------------------------------------------;
; Shift if flag is in high byte to low for byte operations
;
			IF FLAG LT 8		; is in low byte?
FLAG_MASK	= MASK FLAG
FLAG_BIT	= FLAG AND 0111B
FLAG_MEM	= EQUIP_FLAGS[0]			; low BDA flags byte
				IF FLAG + WIDTH FLAG GT 8
					.ERR
					%OUT ERROR: BDA EQFLAG crosses byte boundary
				ENDIF
			ELSE				; is in high byte
FLAG_MASK	= HIGH MASK FLAG
FLAG_BIT	= (FLAG - 8) AND 0111B
FLAG_MEM	= EQUIP_FLAGS[1]			; high BDA flags byte
			ENDIF

	MOV	AL, BYTE PTR FLAG_MEM		; AL = equipment flag byte
	AND	AX, FLAG_MASK			; isolate bits, clear AH

;----------------------------------------------------------------------------;
; Determine optimal number of shifts based on bit position and shift
; right or left depending on fewest.
;
			IF CPU_TYPE	EQ CPU_V20
				IF FLAG_BIT GT 4
	ROL	AL, 8-FLAG_BIT			; shift value into position
				ELSE
					IF FLAG_BIT EQ 4
	ROL4	_AL					; shift value into position
					ELSE
	ROR	AL, FLAG_BIT			; shift value into position
					ENDIF
				ENDIF
			ELSE
				IF FLAG_BIT GT 4	; optimal to roll left
					FLAG_BIT = 8-FLAG_BIT
					IF FLAG_BIT GT 2	; 3-4 shifts use CL
	MOV	CL, FLAG_BIT			; CL = bit(s) position of record
	ROL	AL, CL				; shift value into position
					ELSE		; 0-2 shifts use single op(s)
						REPT FLAG_BIT
	ROL	AL, 1					; shift value into position
						ENDM
					ENDIF
				ELSE			; optimal to roll right
					IF FLAG_BIT GT 2
	MOV	CL, FLAG_BIT			; CL = bit(s) position of record
	ROR	AL, CL				; shift value into position
					ELSE
						REPT FLAG_BIT
	ROR	AL, 1					; shift value into position
						ENDM
					ENDIF
				ENDIF
			ENDIF
			IFNB <SET_BDA>
	POP	DS
	POP	CX
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Set an equipment flag
;----------------------------------------------------------------------------;
; Input: 
;	AL = flag value (clobbered)
;	FLAG = field name from EQUIP_FLAGS RECORD
;	SET_BDA = if defined, saves CL and set DS = BDA 
;		otherwise *requires* DS = BDA and CL clobbered
; Output: none
;----------------------------------------------------------------------------;
SET_EFLAG	MACRO	FLAG, SET_BDA
			IFNB	<SET_BDA>
	PUSH	CX
	PUSH	DS
	MOV	CX, SEG _BDA			; DS = BDA
	MOV	DS, CX
			ENDIF

			IF FLAG LT 8		; is in low byte?
FLAG_MASK	= MASK FLAG
FLAG_BIT	= FLAG AND 111B
FLAG_MEM	= EQUIP_FLAGS[0]			; low BDA flags byte
			ELSE				; is in high byte
FLAG_MASK	= HIGH MASK FLAG
FLAG_BIT	= (FLAG - 8) AND 0111B
FLAG_MEM	= EQUIP_FLAGS[1]			; high BDA flags byte
			ENDIF

	AND	AL, MASK FLAG SHR FLAG		; isolate flag's bit width

;----------------------------------------------------------------------------;
; Determine optimal number of shifts based on bit position and shift
; right or left depending on fewest.
;
			IF CPU_TYPE	EQ CPU_V20
				IF FLAG_BIT GT 4
	ROR	AL, 8-FLAG_BIT			; shift value into position
				ELSE
	ROL	AL, FLAG_BIT			; shift value into position
				ENDIF
			ELSE
				IF FLAG_BIT GT 4
	MOV	CL, 8-FLAG_BIT			; CL = bit(s) position of record
	ROR	AL, CL				; shift value into position
				ELSE
	MOV	CL, FLAG_BIT			; CL = bit(s) position of record
	ROL	AL, CL				; shift value into position
				ENDIF
			ENDIF

	AND	BYTE PTR FLAG_MEM, NOT FLAG_MASK	; clear existing bits(s)
	OR	BYTE PTR FLAG_MEM, AL			; set new bit(s)

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
			IF FLAG LT 8
	TEST	BYTE PTR EQUIP_FLAGS, LOW MASK FLAG
			ELSE
	TEST	BYTE PTR EQUIP_FLAGS[1], HIGH MASK FLAG
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Set a single GLaBIOS flag
;----------------------------------------------------------------------------;
; Input:
;	FLAG = field name from GB_FLAGS RECORD
;	FLAG_CLR = if set, zeros flags first
; Requires: DS = BDA
;----------------------------------------------------------------------------;
SET_GFLAG	MACRO	FLAG, FLAG_CLR
			IFNB	<FLAG_CLR>
	AND	GB_FLAGS, MASK FLAG		; clear existing flag(s)
			ENDIF
	OR	GB_FLAGS, MASK FLAG		; set flag(s)
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
			IF POST_THEME NE 0	; display color
		IFNB	<SAVE_REGS>
	PUSH	AX
	PUSH	BX
	PUSH	CX
		ENDIF ; IFNB
	MOV	AX, DBW <9, VID_SP>	; AH = write char w/attr, AL = space
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
			ENDIF			; END display color
		ENDM

;----------------------------------------------------------------------------;
; POST column UI
;----------------------------------------------------------------------------;
POST_COL_1	MACRO LBL_STR, INNER_ATTR, SAVE_REGS, ZERO_BH
		IFNB	<SAVE_REGS>
	PUSH	BX					; save BX
		ENDIF
		IFNB	<ZERO_BH>
	MOV	BX, LOW INNER_ATTR		; BH = 0, BL = attribute
		ELSE
	MOV	BL, LOW INNER_ATTR		; BL = attribute
		ENDIF
	MOV	SI, OFFSET LBL_STR
	CALL	POST_START_COL_1
		IFNB	<SAVE_REGS>
	POP	BX
		ENDIF

		ENDM

POST_COL_2	MACRO LBL_STR, INNER_ATTR, SAVE_REGS, ZERO_BH
		IFNB	<SAVE_REGS>
	PUSH	BX					; save BX
		ENDIF
		IFNB	<ZERO_BH>
	MOV	BX, LOW INNER_ATTR		; BH = 0, BL = attribute
		ELSE
	MOV	BL, LOW INNER_ATTR		; BL = attribute
		ENDIF
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
BEEP_ON MACRO 	TONE
		IFNB	<TONE>
	MOV	AX, TONE 				; custom tone
		ELSE
	MOV	AX, BEEP_DEFAULT
		ENDIF
	CALL	BEEP_ON_P
		ENDM

;----------------------------------------------------------------------------;
; Beep off Man
;----------------------------------------------------------------------------;
; Input: BL = new PPI state (presumably off)
;----------------------------------------------------------------------------;
BEEP_OFF MACRO
	CALL	BEEP_OFF_P
		ENDM

;----------------------------------------------------------------------------;
; Write to POST status card, if enabled
;----------------------------------------------------------------------------;;
; Input: AL (default) or imm8
;
; Clobbers AL if imm8
;----------------------------------------------------------------------------;
POST_CODE	MACRO	CODE
		IF POST_CARD EQ 1
			IFNB	<CODE>		; if CODE is not blank
			IFDIFI <CODE>,<AL>	; if CODE is not AL
	MOV	AL, LOW CODE
			ENDIF
			ENDIF
	OUT	POST_CARD_PORT, AL
		ENDIF
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
;FILL_BYTE	EQU	0FFH		; Fill with byte (only works on MASM 5.x)

	.LALL
BYTES_HERE	MACRO	NEXT_LBL
		LOCAL LBL

BYTES_HERE_&NEXT_LBL = NEXT_LBL-$

		IFDEF BYTES_HERE_&NEXT_LBL
		IF2
		IF BYTES_HERE_&NEXT_LBL LT 0
		.ERR2
	%OUT WARNING: Out of space at: NEXT_LBL (&BYTES_HERE_&NEXT_LBL)
		ELSE
		IFDEF FILL_BYTE
			REPT BYTES_HERE_&NEXT_LBL
	DB	FILL_BYTE
			ENDM
		ENDIF
		ENDIF
		ENDIF
		ENDIF
		ENDM

;----------------------------------------------------------------------------;
; x86/V20 Instruction MACROs
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; AAM, AAD with immediate other than 0AH
;
AAM_I		MACRO	IMM
	DB	0D4H, IMM			; AAM	imm
		ENDM

AAD_I		MACRO	IMM
	DB	0D5H, IMM			; AAD	imm
		ENDM

;----------------------------------------------------------------------------;
; V20 MACROs for instruction mnemonics not supported by MASM
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; V20_R General Purpose Register operands
;
V20_R		RECORD	VRW:5, ROPC:3

;----------------------------------------------------------------------------;
; Format 3 - Single Register OPC, Variant 1
;
V20_F3	RECORD	VF3_OPC:5=11000b, VF3_SRC:3

;----------------------------------------------------------------------------;
; Format 4 - Two Register OPC, Variant 1
;
V20_F4	RECORD	VF4_OPC:2=11b, VF4_DST:3, VF4_SRC:3

;----------------------------------------------------------------------------;
; Registers used as operands for V20 MACROs
;
_AL	EQU	V20_R	<, 000b>		; reg8
_CL	EQU	V20_R <, 001b>
_DL	EQU	V20_R <, 010b>
_BL	EQU	V20_R <, 011b>
_AH	EQU	V20_R <, _AL OR 100b>
_CH	EQU	V20_R <, _CL OR 100b>
_DH	EQU	V20_R <, _DL OR 100b>
_BH	EQU	V20_R <, _BL OR 100b>
_AX	EQU	V20_R <1, _AL>		; reg16
_CX	EQU	V20_R <1, _CL>
_DX	EQU	V20_R <1, _DL>
_BX	EQU	V20_R <1, _BL>
_SP	EQU	V20_R <1, _AH>
_BP	EQU	V20_R <1, _CH>
_SI	EQU	V20_R <1, _DH>
_DI	EQU	V20_R <1, _BH>

;----------------------------------------------------------------------------;
; Format 1 - Opcode with Size (Byte/Word)
;
V20_OP1	MACRO OP, R, IMM
		LOCAL W
	W	= (R AND MASK VRW) SHR VRW		; W=1 if 16, 0 if 8
	DB	0FH, OP OR W				; register Width
	V20_F3 <, R AND MASK ROPC >			; dest register
			IFNB <IMM>
	DB	IMM
			ENDIF
		ENDM

TEST1		MACRO R, IMM
	V20_OP1	18H, R, IMM
		ENDM

SET1		MACRO R, IMM
	V20_OP1	1CH, R, IMM
		ENDM

CLR1		MACRO R, IMM
	V20_OP1	1AH, R, IMM
		ENDM

NOT1		MACRO R, IMM
	V20_OP1	1EH, R, IMM
		ENDM

;----------------------------------------------------------------------------;
; V20 (B)INS (Binary INS) - reg/reg form
;----------------------------------------------------------------------------;
BINS		MACRO D, S
	DB	0FH, 31H
	V20_F4 <, S AND MASK ROPC, D AND MASK ROPC >
		ENDM

;----------------------------------------------------------------------------;
; V20 (B)EXT (Binary EXT) - reg/reg form
;----------------------------------------------------------------------------;
BEXT		MACRO D, S
	DB	0FH, 33H
	V20_F4 <, S AND MASK ROPC, D AND MASK ROPC >
		ENDM

;----------------------------------------------------------------------------;
; ROL4: roll nibbles left in AL through R8
;----------------------------------------------------------------------------;
; R8(low nibble)  = AL(low nibble)
; R8(high nibble) = R8(low nibble)
; AL(low nibble)  = R8(high nibble)
; AL(high nibble) clobbered
;----------------------------------------------------------------------------;
ROL4		MACRO R8
	V20_OP1	28H, R8					; ROL4
		ENDM

;----------------------------------------------------------------------------;
; ROR4: roll nibbles right in AL through R8
;----------------------------------------------------------------------------;
; R8(high nibble) = AL(low nibble)
; R8(low nibble)  = R8(high nibble)
; AL(low nibble)  = R8(low nibble)
; AL(high nibble) clobbered
;----------------------------------------------------------------------------;
ROR4		MACRO R8
	V20_OP1	2AH, R8					; ROR4
		ENDM

;----------------------------------------------------------------------------;
; Operations on POST test FLAGs
;----------------------------------------------------------------------------;
POST_FLAG_TEST MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20 AND (WIDTH FLAG) EQ 1
	TEST1	_BP, FLAG				; V20: is FLAG set?
			ELSE
	TEST	BP, MASK FLAG			; Is FLAG set?
			ENDIF
		ENDM

POST_FLAG_SET MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20 AND (WIDTH FLAG) EQ 1
	SET1	_BP, FLAG				; V20: Set FLAG
			ELSE
	OR	BP, MASK FLAG			; Set FLAG
			ENDIF
		ENDM

POST_FLAG_FLIP MACRO	FLAG
			IF CPU_TYPE	EQ CPU_V20 AND (WIDTH FLAG) EQ 1
	NOT1	_BP, FLAG				; V20: Invert FLAG
			ELSE
	XOR	BP, MASK FLAG			; Invert flag
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; If ZF is needed, set NEED_ZF to use 808x 'AND' instruction instead
;----------------------------------------------------------------------------;
POST_FLAG_CLR MACRO	FLAG, NEED_ZF
				LOCAL USE_V20
			IFNB <NEED_ZF>
USE_V20	EQU	0				; use AND instruction instead
			ELSE
USE_V20	EQU	1				; use CLR1 (ZF unaffected)
			ENDIF
			IF CPU_TYPE	EQ CPU_V20 AND (WIDTH FLAG) EQ 1 AND USE_V20
	CLR1		_BP, FLAG			; V20: Clear FLAG
			ELSE
	AND	BP, NOT MASK FLAG			; Clear flag
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; Jump if Warm Boot
;----------------------------------------------------------------------------;
JWB		MACRO	LBL
			IF WARM_ENABLE EQ 1
	TEST	BP, BP				; is warm boot?
	JS	LBL					; jump if so
			ENDIF
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

;----------------------------------------------------------------------------;
; IRET with all current flags
;----------------------------------------------------------------------------;
IRET_F	MACRO
	RETF	2
		ENDM

;----------------------------------------------------------------------------;
; PUSH multiple (X number of) registers (up to 8)
;----------------------------------------------------------------------------;
PUSHX	MACRO r1, r2, r3, r4, r5, r6, r7, r8
			IFNB <r1>			; exit if last reg
	PUSH	r1 					; push register and repeat
	PUSHX	r2, r3, r4, r5, r6, r7, r8
			ENDIF
		ENDM

;----------------------------------------------------------------------------;
; POP multiple registers (up to 8)
;----------------------------------------------------------------------------;
POPX	MACRO r1, r2, r3, r4, r5, r6, r7, r8
			IFNB <r1>			; exit if last reg
	POP	r1 					; pop register and repeat
	POPX	r2, r3, r4, r5, r6, r7, r8
			ENDIF
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
IVT_08 		DW	?			; INT 08H - Timer
IVT_08_SEG		DW	?			; INT 08H - Timer Segment
IVT_09 		DW	?			; INT 09H - Keyboard
IVT_09_SEG		DW	?			; INT 09H - Keyboard Segment
		ORG 10H*4
IVT_10		DW	?			; INT 10H - BIOS video services
IVT_10_SEG		DW	?			; INT 10H - Segment
		ORG 18H*4
IVT_18		DW	?			; INT 18H - ROM BASIC
IVT_18_SEG		DW	?			; INT 18H - Segment
		ORG 1DH*4
IVT_1D		DD	?			; INT 1DH - CRTC param table
IVT_1E		DD	?			; INT 1EH - Floppy param table
IVT_1F		DD	?			; INT 1FH - User Font bitmap table
_IVT 		ENDS

;----------------------------------------------------------------------------;
; 0000:0400 - BIOS data area (BDA) - Zero Page Segment Addressing
;----------------------------------------------------------------------------;
_BDA_SEG	=	KP < 40H >			; BDA Seg 40H
_BDA_ABS	SEGMENT AT 0H
		ORG	1AH + _BDA_SEG
KB_BUF_HD_ABS	DW	?			; 40:1AH Keyboard buffer head ptr
		ORG	3EH + _BDA_SEG
FD_CAL_ST_ABS	FDC_SF <>			; 40:3EH Floppy drive recalibration
		ORG	40H + _BDA_SEG
FD_MOTOR_CT_ABS	DB	?			; 40:40H FD motor shutoff counter
		ORG	6BH + _BDA_SEG
INT_LAST_ABS	DB	?			; 40:6BH POST / Interrupt happened?
		ORG	72H + _BDA_SEG
WARM_FLAG_ABS	DW	?			; 40:72H Warm Boot Flag
		ORG	80H + _BDA_SEG
KB_BUF_ST_ABS	DW	?			; 40:80H Keyboard buffer start ptr
_BDA_ABS	ENDS

;----------------------------------------------------------------------------;
; 0030:0000 - Bootstrap temporary stack
;----------------------------------------------------------------------------;
_BOOT_STACK	SEGMENT AT 30H
			DW 	80H DUP(?)		; temporary stack
STACK_TOP		LABEL WORD			; top of stack
_BOOT_STACK	ENDS

;----------------------------------------------------------------------------;
; 0040:0000 - BIOS data area (BDA)
;----------------------------------------------------------------------------;
; https://stanislavs.org/helppc/bios_data_area.html
; http://www.bioscentral.com/misc/bda.htm
;----------------------------------------------------------------------------;
_BDA		SEGMENT AT 40H
COM_ADDR		DW	4 DUP(?) 		; 00H  COM1-4 base addresses
LPT_ADDR_B		EQU	$-_BDA		;	 Low byte hack to force short sign-extend encoding
LPT_ADDR		DW	3 DUP(?) 		; 08H  LPT1-3 base addresses
			DW	? 			; 0EH  Extended BIOS data area segment
EQUIP_FLAGS		EQFLAGS <> 			; 10H  Equipment Flags
GB_FLAGS		GFLAGS <> 			; 12H  Custom Equipment Flags
MEM_SZ_KB		DW	?			; 13H  Memory size in kilobytes
MEM_SZ_PC		DW	?			; 15H  Memory size SW2 on 5150
KB_FLAGS		LABEL WORD
KB_FLAGS1		KBFLAGS1 <>			; 17H  Keyboard flags 1
KB_FLAGS2		KBFLAGS2 <>			; 18H  Keyboard flags 2
KB_ALT 		DB	?			; 19H  Alt-keypad entry byte
KB_BUF_HD		DW	?			; 1AH  Keyboard buffer head ptr
KB_BUF_TL		DW	?			; 1CH  Keyboard buffer tail ptr
KB_BUF		DW	16 DUP(?) 		; 1EH  Keyboard buffer
KB_BUF_END		LABEL WORD			; 3EH  End of keyboard buffer (not inclusive)
KB_BUF_END_B	EQU	3EH			;	 Low byte to force short sign-extend encoding
FD_CAL_ST		FDC_SF <>			; 3EH  Floppy drive recalibration status
							;	0 = drive not calibrated
							;	high bit = working interrupt flag
FD_MOTOR_ST		FDC_MF <>			; 3FH  FD motor status
							;	high bit = write operation
FD_MOTOR_CT		DB	?			; 40H  FD motor shutoff counter (decr. by INT 8)
FD_LAST_OP		DB	?			; 41H  BIOS Status of last FD operation
FDC_LAST_ST		FDC_CSB <>			; 42H  FDC command status last result (7 bytes)
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
CAS_TIME_CNT	LABEL WORD			; 67H  5150 Cassette: Counter
ROM_INIT_SS		DW	?			; 67H   or Temp location for SS:SP during block move
CAS_CRC		LABEL	WORD			; 69H  5150 Cassette: CRC
ROM_INIT_SP 	DW	? 			; 69H	  or Option ROM init
CAS_PREV		LABEL	BYTE			; 6BH  5150 Cassette: Previous byte
;FE2010_CONF_REG	LABEL BYTE			; 6BH  FE2010A Config Reg (Standard 63H)
INT_LAST		DB	? 			; 6BH  Reserved for POST / Interrupt happened?
TIMER			TIMER_C <>			; 6CH-70H Timer Counter
BIOS_BREAK		DB	?			; 71H  BIOS break flag (high bit means ctrl-break)
WARM_FLAG		DW	?			; 72H  Warm Boot Flag (1234H to bypass RAM test)
HD_LAST_ST		DB 	? 			; 74H  Status of last hard disk operation (see INT 13,1)
HD_COUNT		DB 	? 			; 75H  Number of hard disks attached
HD_CTRL		DB 	? 			; 76H  XT fixed disk drive control byte
HD_PORT		DB 	? 			; 77H  Port offset to current fixed disk adapter
LPT_TIME_B		EQU	$-_BDA		;	 Low byte hack to force short sign-extend encoding
LPT_TIME		DB	4 DUP(?) 		; 78H  Time-out value for LPT1-4 (in # of 64K LOOPs)
COM_TIME_B		EQU	$-_BDA		;	 Low byte hack to force short sign-extend encoding
COM_TIME		DB	4 DUP(?) 		; 7CH  Time-out value for COM1-4
KB_BUF_ST		DW	?			; 80H  Keyboard buffer start
			DW	?			; 82H  Keyboard buffer end
		ORG	08BH
FD_LR			DB	?			; 8BH  Last diskette data rate selected
		ORG	08FH
FD_MODE		FDC_MODE <>			; 8FH  FDC Drive Mode (see FDC_MODE)
FD_MEDIA_ST		FDC_STATE 4 DUP(<>)	; 90H-93H  Drive 0-3 media state
FD_TRACK		DB	2 DUP(?)		; 94H-95H  Drive 0-1 current track
EKB_FLAGS1		KBFLAGS3 <>			; 96H  Keyboard mode/type (Enhanced)
EKB_FLAGS2		KBFLAGS4 <>			; 97H  Keyboard LED flags (Enhanced)
		ORG	0A0H
RTC_WAIT		DB	?			; A0H  RTC wait function flag
		ORG	0ACH				; ACH-B3H "Reserved" (can be used?)
		ORG	0B0H				; B0H-B1H (used by Tandy for keyboard)
		ORG	0E8H				; E8H-EFH "Reserved" (can be used?)
VID_MEM_SEG_DW	LABEL DWORD			; E8H-EAH Video mem segment using LDS/LES
CURSOR_DEFAULT	DW	?			; E8H  Power on cursor bottom:top scan line (for Turbo)
VID_MEM_SEG		DW	?			; EAH	 Video mem segment (MDA = B000, CGA = B800)
FE2010_CONF_REG	DB	?			; ECH  FE2010A Config Reg (63H) (alternate)
			DB	?			; EDH
RTC_DATA		DW	?			; EEH  GLaTICK address and RTC type
_BDA		ENDS

;----------------------------------------------------------------------------;
; 0050:0000 - BIOS/DOS Data Area
;----------------------------------------------------------------------------;
_DOS_DAT	SEGMENT AT 50H
PTRSCN_ST		DB 	?			; 00H  Print screen status
			DB	3  DUP(?)		; 01H  Used by BASIC
			DB	?			; 04H  Floppy drive flag for single
							;	  drive systems (0=A,1=B)
			DB	10 DUP(?)		; 05H  POST work area
			DB	19 DUP(?)		
DOS_FD_PARAM	DB	14 DUP(?)		; 22H  Floppy drive parameter table
			DB	4  DUP(?)		; 30H  Mode command
_DOS_DAT	ENDS

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
MDA_MEM		DB	1000H DUP(?)	; 4KiB (1000H) total MDA memory
_MDA_MEM	ENDS

;----------------------------------------------------------------------------;
; B800:0000 - CGA Video Memory
;----------------------------------------------------------------------------;
_CGA_MEM	SEGMENT AT 0B800H
CGA_MEM_40		DB	0800H DUP(?)	; page 1 of CGA 40 column (2K)
CGA_MEM_80		DB	3800H DUP(?)	; pages 1-4 of CGA 80 column (14K)
CGA_MEM_SZ		= SIZE CGA_MEM_40 + SIZE CGA_MEM_80	; 16 KiB (4000H) total CGA memory
CGA_MEM_FLD 	= CGA_MEM_SZ / 2		;  8 KiB (2000H) CGA memory field
_CGA_MEM	ENDS

;----------------------------------------------------------------------------;
; C000:0000 - Video Option ROM segment
;----------------------------------------------------------------------------;
_VID_BIOS	SEGMENT AT 0C000H
VID_MN		DW	?			; magic number (0AA55H)
VID_BIOS_SZ		DB	?			; length in 512 byte blocks
VID_VEC		DW	?			; FAR call to ROM init routine
_VID_BIOS	ENDS

;----------------------------------------------------------------------------;
; C800:0000 - Start of Storage/Other Option ROM segment
;----------------------------------------------------------------------------;
_OPT_ROM	SEGMENT AT 0C800H
_OPT_ROM	ENDS

;----------------------------------------------------------------------------;
; F000:E000 - System BIOS ROM segment map
;----------------------------------------------------------------------------;
_BIOS		SEGMENT AT 0F000H
		ORG	0E000H
_BIOS_TOP	LABEL FAR
		ORG	0E05BH
_BOOT		LABEL FAR				; BIOS boot offset
		ORG	0FFF0H
_POWER_ON	LABEL FAR				; CPU power-on jump address
_BIOS		ENDS

;----------------------------------------------------------------------------;
; F600:0000 - ROM BASIC segment
;----------------------------------------------------------------------------;
_BASIC	SEGMENT AT 0F600H
BASIC_TOP	DW	? 				; ROM BASIC top of code
_BASIC	ENDS

;----------------------------------------------------------------------------;
; FFFF:0000: 8086 power-on reset vector
;----------------------------------------------------------------------------;
; The x86 CPU begins code excution at hard-coded address FFFF:0000.
; This is that address. Welcome to the party!
;----------------------------------------------------------------------------;
RESET    	SEGMENT AT 0FFFFH
__POWER_ON	LABEL	FAR				; FFFF:0000
RESET		ENDS

;============================================================================;
;
;				* * *   C O D E   * * * 
;
;============================================================================;

;----------------------------------------------------------------------------;
; Main BIOS ROM begins
;----------------------------------------------------------------------------;
; Note: Memory space from F000:0000 - F000:E05A is available, though a
; BIOS identifier string is typically at or near the top of this segment
;----------------------------------------------------------------------------;
		ASSUME	DS:BIOS, SS:BIOS, CS:BIOS, ES:BIOS
BIOS    	SEGMENT

;----------------------------------------------------------------------------;
; F000:FFF0: 8086 power-on reset vector
;----------------------------------------------------------------------------;
; The x86 CPU begins code excution at hard-coded address FFFF:0000.
; This is that address. Welcome to the party!
;----------------------------------------------------------------------------;
		ORG	0FFF0H
POWER_ON	PROC	FAR
	JMP	_BOOT 			; FAR jump to power on routine
POWER_ON	ENDP

		ORG	0FFF5H
REL_DATE 	DB	VER_DATE		; Release date

		ORG	0FFFEH
ISA_TYPE	DB	ARCH_ID		; Architecture model

		ORG	0FFFFH		; BIOS ROM checksum byte 
		DB	?			; (computed at build time)

;----------------------------------------------------------------------------;
; F000:E000: Top of BIOS ROM 8K segment
;----------------------------------------------------------------------------;
		ORG	0E000H
BIOS_TOP	PROC	NEAR

TOP_BANNER	DB	LF
		DB	VER_NAME, ' [', HEART, '] '
				IF RANDOM_TAGLINE EQ 1
		DB	0				; null terminate BANNER string
				ENDIF
TAG0		DB	'Reboot the Past'
				IF RANDOM_TAGLINE EQ 1
		DB	0				; null terminate TAG0 string
				ENDIF
COPYRIGHT	DB	CR, LF
		DB	'(C) ', COPY_YEAR, ' '
		DB	'640KB Released under GPLv3'
		DB	LF
		DB	0

BIOS_TOP 	ENDP

;----------------------------------------------------------------------------;
; Display a zero-terminated string in BIOS at CS:[SI] with ending NL
;----------------------------------------------------------------------------;
; Input: CS:SI = String
; Size: 12 bytes
;----------------------------------------------------------------------------;
OUTLN_SZ PROC
	CALL	OUT_SZ			; write original string in SI
						; fall through to CRLF
;----------------------------------------------------------------------------;
; Write a CRLF string to console
;----------------------------------------------------------------------------;
CRLF PROC
	PRINT_SZ  NL_Z, 1
	RET
CRLF ENDP
OUTLN_SZ ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	BOOT

			ASSUME CS:BIOS, DS:NOTHING, ES:NOTHING, SS:NOTHING
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
		ORG	0E05BH
BOOT	PROC	NEAR

			IF INIT_V40 EQ 1 OR INIT_AT_KBC EQ 1
;----------------------------------------------------------------------------;
; Cold boot chipset setup for V40 and AT KBC
;
	CLI
	JMP	COLD_INIT
COLD_INIT_DONE:
			ENDIF

			IF ARCH_TYPE EQ ARCH_TD3300 AND ARCH_SUB_TYPE EQ ARCH_NEST
;----------------------------------------------------------------------------;
; Cold boot chipset setup for D-11
;
	CLI
	IN	AL, N3_CTRL
	OR	AL, MASK D11SX OR MASK D11B
	OUT	N3_CTRL, AL
			ENDIF

BOOT_WARM LABEL NEAR
;----------------------------------------------------------------------------;
; Warm boot (Ctrl-Alt-Del)
;
	CLI					; disable CPU interrupts
	CLD

;----------------------------------------------------------------------------;
; POST Hardware/System Tests
;----------------------------------------------------------------------------;

POST_CPU_TEST:
;----------------------------------------------------------------------------;
; [1] Test and clear all CPU Registers
;----------------------------------------------------------------------------;
; Check and set all registers to 0.
;
; On Failure: 2 short and 1 long beep
;----------------------------------------------------------------------------;
			ASSUME DS:_BDA_ABS, ES:_IVT
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
	MOV	BL, BEEP_SL <2,1>		; on Failure: 2 short and 1 long beep
	JNZ	HALT_ERROR
	XOR	AX, AX 			; otherwise repeat with AX = 0
	TEST	DX, DX			; if zero it was second pass
	JNZ	CPU_REG_TEST		; Loop again to zero all registers
CPU_REG_PASS:

;----------------------------------------------------------------------------;
; [1B] A brief test of flags and CPU instructions
;----------------------------------------------------------------------------;
; On Failure: 2 short and 1 long beep
;----------------------------------------------------------------------------;
			IF POST_TEST_INST EQ 1
CPU_INST_TEST:
	MOV	AL, 1				; start off with some complicated math
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
; [2] Disable non-maskable interrupts (NMIs)
;----------------------------------------------------------------------------;
DISABLE_NMI:
	OUT	NMI_R0, AL			; write AL = 0 to NMI register port

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
	POST_CODE				; optionally display 01 on POST card

;----------------------------------------------------------------------------;
; Set up POST flags in BP
;----------------------------------------------------------------------------;
	CMP	WARM_FLAG_ABS, WARM_BOOT
	JNZ	POST_FLAG_DONE
	MOV	BP, MASK WARM		; clear and set POST warm boot flag
POST_FLAG_DONE:

			IF RANDOM_TAGLINE EQ 1
;----------------------------------------------------------------------------;
; Read PIT for seed of random pithy tagline
;----------------------------------------------------------------------------;
	DEC	AX				; Counter 0, Latch (00b)
	OUT	PIT_CTRL, AL		; write command to CTC
	IN	AL, PIT_CH0			; read low byte of Counter 0 latch
	SHR	AL, 1				; low bit is always 0
	AND	AL, MASK GRND		; use only last two bits
	OR	BP, AX			; save to low bits of BP
			ENDIF

;----------------------------------------------------------------------------;
; Setup SS = CS
;----------------------------------------------------------------------------;
; Set up temporary stack to point at ROM to enable CALL_NS MACRO
;----------------------------------------------------------------------------;
	MOV	DX, CS 			; DX = 0F000h (BIOS segment)
	MOV	SS, DX			; SS = temp boot stack in CS

;----------------------------------------------------------------------------;
; [5] Setup 8255 PPI to normal operating state
;----------------------------------------------------------------------------;
; Normal operation: Mode 0, Ports A,C (U and L) as INPUT, Port B as OUTPUT
;----------------------------------------------------------------------------;
RESET_PPI:
			IF ARCH_TYPE EQ ARCH_FE2010
	MOV	AL, FE_CR <>		; set speed 9.54MHz, Memory 640KB, no FPU
			ELSE
	MOV	AL, PPI_CR <>		; set 8255 A,C to INPUT, B to OUTPUT
			ENDIF
	OUT	PPI_CW, AL 			; send to PPI control port (63H)

;----------------------------------------------------------------------------;
; Set up PPI port B
;
	MOV	AL, PPI_B_BOOT		; KB hold low+disable, NMI on, spkr off
	OUT	PPI_B, AL			; send to 8255 Port B

			IF ARCH_TYPE EQ ARCH_TD3300
			IF ARCH_SUB_TYPE EQ ARCH_NEST
;----------------------------------------------------------------------------;
; Nest N3 setup part 2 - WARM or COLD
; - Enable/Disable UMA at E000 according to N3_UMA
; - Set initial speed according to BOOT_SPEED
;
	IN	AL, N3_CTRL
				IF BOOT_SPEED EQ BOOT_TURBO	; BOOT_TURBO
				IF N3_UMA
	OR	AL, MASK D11SX OR MASK D11B OR MASK D11UM	OR MASK D11SF ; enable upmem
	AND	AL, NOT MASK D11SS				; clear speed bit
				ELSE
	OR	AL, MASK D11SX OR MASK D11B OR MASK D11SF	; set speed flag
	AND	AL, NOT MASK D11SS AND NOT MASK D11UM	; clear speed bit, disable upmem
				ENDIF
				ELSE					; BOOT_NORMAL
				IF N3_UMA
	OR	AL, MASK D11UM OR MASK D11SX			; enable upper memory
				ELSE
	OR	AL, MASK D11SX					; enable speed
	AND	AL, NOT MASK D11UM				; disable upper memory
				ENDIF
	XOR	AL, MASK D11SS					; flip hardware speed bit to set
				ENDIF
	OUT	N3_CTRL, AL

			ELSE
;----------------------------------------------------------------------------;
; Set up TD3300 Turbo, wait states and bank switching. If TD_UPMEM, it will
; be set later.
;
				IF TD_UPMEM EQ 0
	XCHG	AX, SI			; AX = 0
	OUT	TD_MEM, AL			; set TD3300 memory bank 0
				ENDIF

	IN	AL, TD_TURBO		; read current turbo register
				IF BOOT_SPEED EQ BOOT_TURBO
	MOV	AL, TD_TURBO_CR <,,0>	; switch to turbo
				ELSE
	MOV	AL, TD_TURBO_CR <,,1>	; switch to normal (4.77)
				ENDIF
	OUT	TD_TURBO, AL		; write new register
			ENDIF			; ENDIF EQ ARCH_NEST
			ENDIF			; ENDIF EQ ARCH_TD3300

			IF ARCH_TYPE EQ ARCH_LASER
;----------------------------------------------------------------------------;
; Set up the initial boot speed. Real hardware boots at normal speed.

	MOV	DX, LASER_TURBO		; store speed control port
				IF BOOT_SPEED EQ BOOT_TURBO
	MOV	AL, LASER_CR <1>		; switch to turbo
				ELSE
	MOV	AL, LASER_CR <0>		; switch to normal
				ENDIF
	OUT	DX, AL			; write to speed control port
	MOV	DX, SS			; restore DX
			ENDIF			; ENDIF ARCH_LASER

;			IF (ARCH_TYPE EQ ARCH_EMU) AND (ARCH_SUB_TYPE EQ ARCH_MIST)
;----------------------------------------------------------------------------;
; Set up Turbo mode for PCXT_MiSTer
;
;	MOV	DX, MC_PORT			; DX = XTCTL port
;	IN	AL, DX			; read current speed
;	AND	AL, NOT MCSP_SPD		; clear speed bits
;			IF BOOT_SPEED EQ BOOT_TURBO
;	OR	AL, MC_XTCTL <MCSP_AT4>	; boot to AT 4MHz
;			ELSE
;	OR	AL, MC_XTCTL <,,,,MCSP_5> ; boot to XT 5MHz
;			ENDIF
;	OUT	DX, AL			; set new speed
;	MOV	DX, SS			; restore DX
;			ENDIF			; ARCH_MIST

			IF POST_TEST_CHK_ROM EQ 1
;----------------------------------------------------------------------------;
; [8] Checksum (8 bit) the main ROM to ensure it is not corrupt
;----------------------------------------------------------------------------;
; Input: AH = 0, BL = 21h, CX = 0, DX = 0F000h
; On Failure: 2 long and 2 short beeps
;----------------------------------------------------------------------------;
	JWB	CHECKSUM_OK			; skip on warm boot
CHECKSUM_ROM:
			ASSUME DS:BIOS
	INC	BX				; on failure, 2 short and 2 long beeps
	MOV	DS, DX			; DS to 0F000h BIOS segment
	MOV	SI, OFFSET BIOS_TOP 	; offset to top of BIOS ROM
	MOV	CH, HIGH KBW < 8 >	; checksum 8KB (in 2 byte words)
CHECKSUM:
	LODSW 				; next two bytes into AL and AH
	ADD	DL, AL			; DL = running checksum
	ADD	DL, AH			; ZF if sum is 0
	LOOP	CHECKSUM 			; loop through entire ROM
	JNZ	HALT_ERROR			; if sum not 0, fail
CHECKSUM_OK:
			ENDIF

;----------------------------------------------------------------------------;
; [9] Disable the 8237 DMA controller chip.
;----------------------------------------------------------------------------;
INIT_DMA1:
	MOV	AL, MASK DDIS		; Set Controller Disable bit
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
; Output: Success SI and DI = 0, Failure 3 short, 2 long beeps
;----------------------------------------------------------------------------;
		IF DRAM_REFRESH GT 0	; is DRAM refresh enabled?
	MOV	AL, PIT_CW <1, 11B, 2>	; Control Word: Counter 1
						;   Format: R/W low/high byte: 11b
						;   Mode: 2 Rate Gen, BCD: 0
	MOV	DX, LOW PIT_CH1		; DX = PIT channel 1
		ELSE
	MOV	AL, PIT_CW <0, 11B, 2>	; if no DRAM refresh, test timer 0 instead
	MOV	DX, LOW PIT_CH0		; DX = PIT channel 0
		ENDIF
	OUT	PIT_CTRL, AL		; set Counter mode
	OUT	DX, AL			; set low byte (any value)
	MOV	SI, 0FFH SHL 3		; flag bits 10-3 for 1 check
	MOV	DI, NOT 0FFH SHL 3	; flag bits 10-3 for 0 check
	OUT	DX, AL			; set high byte (any value)
INIT_PIT1_TEST:
	TEST	DI, DI			; have all bits flipped to 0?
	JNZ	INIT_PIT1_TEST_READ	; if not, keep reading PIT
	INC	SI				; have all bits flipped to 1?
	JZ	INIT_PIT1_TEST_DONE	; if so, success
	DEC	SI				; if not, undo INC and keep reading PIT
INIT_PIT1_TEST_READ:
		IF DRAM_REFRESH GT 0	; is DRAM refresh enabled?
	MOV	AL, PIT_CW <1,0>		; latch Counter 1 command
		ELSE
	MOV	AL, PIT_CW <0,0>		; latch Counter 0 command
		ENDIF
	OUT	PIT_CTRL, AL		; write command to CTC
	IN	AL, DX			; read timer LSB
	MOV	AH, AL			; save LSB
	IN	AL, DX			; read timer MSB
	AND	DI, AX			; clear all lines read as 0
	OR	SI, AX			; set all lines read as 1
	LOOP	INIT_PIT1_TEST		; loop until timeout
	MOV	BL, BEEP_SL <3,2>		; beep pattern (3 short, 2 long)
HALT_ERROR:
	JMP	SHORT HALT_BEEP_1		; NEAR jump for POST errors
			ELSE
	JMP	SHORT INIT_PIT1_TEST_DONE ; jump over the NEAR jump
HALT_ERROR:
	JMP	SHORT HALT_BEEP_1		; must still be here if PIT test is off
			ENDIF

INIT_PIT1_TEST_DONE:

;----------------------------------------------------------------------------;
; [9B] 8253 PIT Programmable Interval Timer Initialization Channel 1
;----------------------------------------------------------------------------;
; Counter 1 - DRAM Refresh
;----------------------------------------------------------------------------;
INIT_PIT1:
			IF DRAM_REFRESH GT 0FFH
;----------------------------------------------------------------------------;
; Program PIT with H/L bytes
;
		IF POST_TEST_PIT_1 NE 1	; skip if already programmed from PIT test
	MOV	AL, PIT_CW <1, 11B, 2>	; Control Word: Select Counter(SC): 1
						;   Format(RW): 11b (R/W low/high byte)
						;   Mode(M): 2 (Rate Gen), BCD: 0 (Binary)
	OUT	PIT_CTRL, AL		; set Counter mode
		ENDIF

			ELSE
;----------------------------------------------------------------------------;
; Program PIT with single byte
;
	MOV	AL, PIT_CW <1, 01B, 2>	; Control Word: Select Counter(SC): 1
						;   Format(RW): 01b (R/W byte LE)
						;   Mode(M): 2 (Rate Gen), BCD: 0 (Binary)
	OUT	PIT_CTRL, AL		; set Counter mode

			ENDIF

;----------------------------------------------------------------------------;
; [12] Reset, Clear and test DMA Offset and Block Size Registers
;----------------------------------------------------------------------------;
; - Master Reset of DMA controller
; - Test 8237 DMA Address/Count Register channels 0-3
;----------------------------------------------------------------------------;
	OUT	DMA_RESET, AL 		; Master Reset (send any value of AL)

			IF POST_TEST_DMA EQ 1
	MOV	AH, 8				; test 8 ports
	CWD					; starting at port 00H
	CALL_NS  PORT_TEST		; ZF and CX = 0 if pass, NZ if failed
	MOV	BL, BEEP_SL <4,2>		; beep pattern (4 short, 2 long)
	JNZ	HALT_ERROR
DMA_PASS:
	OUT	DMA_RESET, AL 		; master reset of DMA again
			ENDIF			; POST_TEST_DMA

			IF DRAM_REFRESH GT 0
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
;     10 		; type: Read from memory (2)
;       00 		; Channel 0
;----------------------------------------------------------------------------;
	MOV	AL, DMA_MR <1,0,1,2,0>
	OUT	DMA_MODE, AL		; write to DMA Mode Register

;----------------------------------------------------------------------------;
; [13B] 8253 Timer set channel #1 for DMA/DRAM refresh
;----------------------------------------------------------------------------;
	MOV	AL, LOW DRAM_REFRESH	; set low byte of divisor
	OUT	PIT_CH1, AL			; 
				IF DRAM_REFRESH GT 0FFH
	MOV	AL, HIGH DRAM_REFRESH	; set high byte of divisor
	OUT	PIT_CH1, AL			; 
				ENDIF
			ENDIF

;----------------------------------------------------------------------------;
; [13C] Enable DMA and clear mask register on Channels 0-3
;----------------------------------------------------------------------------;
	MOV	AL, DMA_CR <>		; Set Controller Enable bit
	OUT	DMA_CMD, AL 		; write to DMA Command Register
	MOV	CL, 3				; Set mode on Channels 1-3 for [13D]
						;  (and I/O delay between OUTs)
	OUT	DMA_MASK, AL		; clear mask (enable) on all channels

;----------------------------------------------------------------------------;
; [13D] Set default Mode for DMA Channels 1-3
;----------------------------------------------------------------------------;
; 01 			; Mode 1 (Single)
;   0 		; INC: address decrement
;    0 		; No Auto-initialization
;     00 		; type: Verify (0)
;       xx 		; Channels 1-3
;
; Input: CL = 3 (from [13C]), CH = 0 (from CALL_NS in [12])
;----------------------------------------------------------------------------;
	MOV	AL, DMA_MR <1,0,0,0,1>	; start with channel 1
DMA_SETUP_CH:
	OUT	DMA_MODE, AL		; write to DMA Mode Register
	INC	AX				; next channel
	LOOP	DMA_SETUP_CH		; (delay 13-17 clocks between OUTs)

			IF EXP_UNIT EQ 1
;----------------------------------------------------------------------------;
; [14] Detect and enable 5161 expansion chassis / extension card
;----------------------------------------------------------------------------;
; http://minuszerodegrees.net/5161/doco/5161_documentation.htm
;
; http://minuszerodegrees.net/5161/misc/5161_not_supported.htm
; "note: research revealed that the substituted code is not required; the
; circuit diagram of the extender card shows that the card is automatically
; enabled at application of power."
;
; Based on the above, it would appear this may not be necessary.
;----------------------------------------------------------------------------;
INIT_EXP_CHASSIS:
	MOV	DX, EXP_UNIT_CTRL		; PC Expansion Chassis
			IF 0			; test for card first?
	IN	AL, DX
	INC	AL 				; Is 213H == 0FFH?
	JZ	INIT_EXP_CHASSIS_DONE 	; if so, no expansion chassis
			ENDIF
	MOV	AL, 1 			; otherwise, send 1 to enable
	OUT	DX, AL
INIT_EXP_CHASSIS_DONE:
			ENDIF

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
	MOV	SI, OFFSET WARM_FLAG_ABS	; SI = warm boot flag offset
	MOV	DX, [SI]				; save warm boot flag
	CALL_NS  MEM_CHECK			; clear memory and parity bits
	JNZ	BASE_RAM_ERROR
	IN	AL, PPI_B				; read PPI channel B
	OR	AL, MASK PBPC 			; clear MB RAM parity flag only
	OUT	PPI_B, AL
	AND	AL, NOT MASK PBPC 		; enable MB RAM parity for test
	OUT	PPI_B, AL
	CALL_NS  MEM_ADDR_TEST			; test address lines
	JZ	BASE_RAM_ZERO			; continue if no errors
BASE_RAM_ERROR:
	MOV	BL, BEEP_SL <1,3>			; on failure, 1 short and 3 long beeps
HALT_BEEP_1:
	JMP	HALT_BEEP				; NEAR jump to HALT BEEP PROC
BASE_RAM_ZERO:
	MOV	AX, RAM_TEST			; test pattern
	CALL_NS  MEM_CHECK			; write and verify test pattern
	JNZ	BASE_RAM_ERROR			; ZF and AX = 0 if okay
	CALL_NS  MEM_CHECK			; write and verify zeros
	JNZ	BASE_RAM_ERROR
	XCHG	[SI], DX				; restore warm boot flag, DX = 0
	INC	AX					; AL = 1
	MOV	FD_MOTOR_CT_ABS, AL 		; set motor to turn off on next tick
			IF RAM_PARITY EQ 1
	IN	AL, PPI_C				; read PPI channel C
	AND	AL, MASK PCPE			; check MB RAM parity flag
	JZ	BASE_RAM_TEST_DONE		; either set?
	MOV	BL, BEEP_SL <1,4>			; Halt with 1 short beep, 4 long beeps
	JMP	SHORT HALT_BEEP_1
BASE_RAM_TEST_DONE:
	IN	AL, PPI_B
	OR	AL, MASK PBIO OR MASK PBPC	; disable RAM parity and I/O ch. flags
	OUT	PPI_B, AL
			ENDIF				; END RAM_PARITY EQ 1

;----------------------------------------------------------------------------;
;
; YAY! It's now okay to use the first 16KB of RAM: 0000:0000-0000:1FFF
;
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; [18] Setup BOOT R/W stack memory segment
;----------------------------------------------------------------------------;
			ASSUME SS:_BOOT_STACK
	MOV	AX, SEG STACK_TOP 		; SS:SP to temp boot stack 0030:0100
	MOV	SS, AX
	MOV	SP, OFFSET STACK_TOP

;----------------------------------------------------------------------------;
; [19] 8259A PIC Interrupt controller Initialization
;----------------------------------------------------------------------------;
; PIC chip Initialization as follows:
;
; ICW1:
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
;     0		- SFNM: 0 = Not Special Fully Nested Mode
;      10		- BUF:  2 = Buffered Mode/Slave
;        0		- AEOI: 0 = normal EOI
;         1		- uPM:  1 = 8086 system
;----------------------------------------------------------------------------;
	MOV	DL, LOW INT_P0		; DX = PIC Port 0
	MOV	AL, ICW1 <1,0,0,1,1>	; AL = ICW1 - Port 0
	OUT	DX, AL
	INC	DX				; DX = PIC Port 1
	MOV	AX, DBW <1,ICW2 <1>> 	; AL = ICW2 - Port 1, AH = PORT_TEST count
	OUT	DX, AL
	INC	AX				; AL = ICW4 <0,2,0,1> - Port 1
	OUT	DX, AL

			IF POST_TEST_PIC_REG EQ 1
;----------------------------------------------------------------------------;
; [22] 8259A PIC Test
;----------------------------------------------------------------------------;
; - Read and write registers (IMR) and verify result
;----------------------------------------------------------------------------;
	CALL	PORT_TEST			; test of PIC IMR register
	MOV	BL, BEEP_SL <5,2>		; beep error 5 short, 2 long
	JZ	PIC_REG_PASS
PIC_INT_FAIL:
	JMP	SHORT HALT_BEEP_1
PIC_REG_PASS:
	DEC	DX				; DX = Port 1 (0021h)
			ELSE
	NOP
			ENDIF			; IF POST_TEST_PIC_REG EQ 1

	MOV	AL, OCW1 <1,1,1,1,1,1,1,1> ; OCW1 - mask all interrupts (for now)
	OUT	DX, AL			; write IMR to PIC

			IF POST_TEST_PIC_INT EQ 1
;----------------------------------------------------------------------------;
; - Set up test interrupt handler for all interrupts
;
PIC_INT_TEST:
	MOV	CL, 1FH			; 0 - 1EH BIOS vectors (LOW L_VECTOR_TABLE)
	XOR	DI, DI			; DI = beginning to IVT
PIC_VECT_TMP_LOOP:
	MOV	AX, OFFSET INT_IRQ	; offset for handler
	STOSW					; write to IVT (ES=0000 from CPU_REG_TEST)
	MOV	AX, CS			; segment for handler (BIOS)
	STOSW					; write to IVT
	LOOP	PIC_VECT_TMP_LOOP

;----------------------------------------------------------------------------;
; - Mask all interrupts and ensure none are received
; Input: AL = 0 (from MOV AX, CS)
;
	MOV	DI, OFFSET INT_LAST_ABS
	MOV	[DI], AL			; clear last interrupt flag
	STI					; enable interrupts
	IO_DELAY				; wait for it...
	CLI
	INC	BX				; beep error 5 short, 3 long
	OR	[DI], AL			; did any interrupts happen?

			IF POST_TEST_PIC_REG EQ 1
	JNZ	PIC_INT_FAIL
			ELSE
	JZ	PIC_INT_PASS
	JMP	SHORT HALT_BEEP_1
			ENDIF			; IF POST_TEST_PIC_REG EQ 1
			ENDIF			; IF POST_TEST_PIC_INT EQ 1

	MOV	AL, NOT MASK IRQ0		; OCW1 - unmask timer
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
	MOV	AL, PIT_CW <0, 11B, 3>	; Control Word: Select Counter(SC): 1
						;   Format(RW): 11b (Read/Write 2xR/2xW)
						;   Mode(M): 2 (Rate Gen), BCD: 0 (Binary)
	OUT	PIT_CTRL, AL
	PUSH	CS				; I/O delay and set up for DS = CS below

;----------------------------------------------------------------------------;
; This is what generates IRQ 0 (system timer).
; Timer set channel #0 output to a square wave of approx. 18.2 Hz based on
;	f = 1,193,181.81 / 10000H = ~ 18.2Hz
; Reload counter to WORD (0) to port 40H
;
	XOR	AL, AL			; reload counter is 2^16 (0) ~ 18.2Hz
	OUT	PIT_CH0, AL	  		; send low byte
	POP	DS				; I/O delay and set DS = CS
	OUT	PIT_CH0, AL 		; send high byte

;----------------------------------------------------------------------------;
; [25] Setup default BIOS interrupt vectors (00h - 01Eh)
;----------------------------------------------------------------------------;
; All segments are set to BIOS (CS) segment by default.
; INT 1Fh is skipped and left as 0000:0000.
; Exceptions (such as ROM BASIC) are reset below.
; Input: ES = 0000 from CPU_REG_TEST
;----------------------------------------------------------------------------;
			ASSUME DS:BIOS, ES:_IVT
INIT_SW_INT_VECTORS:
	MOV	AX, CS 			; AX to BIOS segment
	MOV	CL, 1FH			; 0 - 1EH BIOS vectors (LOW L_VECTOR_TABLE)
	XOR	DI, DI			; DI = beginning to IVT
	MOV	SI, OFFSET VECTOR_TABLE
BIOS_INT_VECTORS_LOOP:
	MOVSW 				; copy vector offset to IVT
	STOSW 				; write BIOS/CS segment
	LOOP	BIOS_INT_VECTORS_LOOP	; loop and set CX = 0

			IF BASIC_ROM EQ 1
;----------------------------------------------------------------------------;
; Check for valid BASIC ROMs and set INT 18H vector if detected
;----------------------------------------------------------------------------;
; - Scan 4 x 8K ROMs starting at seg 0F600h.
; - BASIC dectected if for all ROMs, all of the folowing are true:
; 	- first two bytes not option ROM (0AAFFh)
;	- first two bytes not the same as the previous ROM (this checks to
;		 make sure are not all 0000 or FFFF)
;	- 8K ROM block has a valid checksum at offset 1FFE
;----------------------------------------------------------------------------;
			ASSUME DS:_BASIC
INIT_ROM_BASIC_SEG:
	MOV	BX, SEG _BASIC 			; BX = BASIC SEG in ROM
	MOV	SI, BX				; SI = save first BASIC SEG
	MOV	DI, MAGIC_WORD			; start with a negative check result
	MOV	CL, 4					; checksum 4 x 8K ROMs
CHECK_BASIC_ROM:
	MOV	DS, BX				; set DS to current segment
	MOV	AX, BASIC_TOP			; AX = first two bytes of ROM
	CMP	AX, MAGIC_WORD			; is an option ROM?
	JE	INIT_ROM_BASIC_DONE		; if so, not ROM BASIC
	XCHG	AX, DI				; save last ROM's header to DI
	CMP	AX, DI				; is same as last ROM?
	JE	INIT_ROM_BASIC_DONE		; if so, valid ROM not present
	MOV	AX, KB < 8 > / 512 		; 8K ROM size (in 512B blocks)
	ADD	BH, HIGH KBP < 8 >		; BX = next BASIC 8K ROM segment
	CALL	ROM_CHECKSUM 			; checksum ROM at DS:0, size AX
	LOOPZ	CHECK_BASIC_ROM			; loop 4 ROMs or checksum fail
	JNZ	INIT_ROM_BASIC_DONE		; if NZ, checksum failed

;----------------------------------------------------------------------------;
; BASIC ROM detected - set as INT 18h in IVT
;
	MOV	DI, OFFSET IVT_18			; DI = BASIC offset in IVT
	XCHG	AX, CX				; AX = vector offset 0000
	STOSW 					; write to IVT
	XCHG	AX, SI 				; AX = BASIC SEG
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
CPU_IS_V20:
	MOV	AX, DBW <1,1>			; Attempt to pack bytes into nibbles
	AAD_I	10H					; result is 11 if V20, 11H if x86
	CMP	AL, 11				; ZF = 1 if V20, ZF = 0 if 8088
	JNE	CPU_TYPE_8088			; jump if not V20
	SET_GFLAG	V20				; set V20 flag
			IF CPU_TYPE	EQ CPU_V20
	JMP	SHORT CPU_TYPE_DONE		; continue booting
CPU_TYPE_8088:
	MOV	BL, BEEP_SL <4,1>			; Build is V20 but not detected
	JMP	SHORT HALT_BEEP_2			;  beep 4 short, 1 long
			ELSE
CPU_TYPE_8088:
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
; EQUIP_FLAGS: LPT:2,X1:1,GAM:1,COM:3,DMA:1,FLP:2,VID:2,MBRAM:2,FPU:1,IPL:1
;----------------------------------------------------------------------------;
GET_SW_SETTINGS:
	IN	AL, PPI_B 				; read Port B register
	PUSH	AX					; save original switches, AH = 0

		IF ARCH_TYPE EQ ARCH_5150
;----------------------------------------------------------------------------;
; On 5150, memory size is read from SW1 (motherboard RAM) and SW2 (I/O expansion
; RAM) added together. Note: motherboard RAM is always counted as 16-64K, even
; on 64-256K revisions, with expansion RAM size (SW2) equalling size of memory
; above 64K.
;
SETTINGS_5150:
			IF CPU_TYPE EQ CPU_V20
	CWD						; DX = 0
			ENDIF
	OR	AL, MASK PBKB OR MASK PBSW	; Enable SW1 switches, SW2 1-4
	OUT	PPI_B, AL
	XCHG	AX, CX				; save modified settings

;----------------------------------------------------------------------------;
; Read expansion card memory size from SW2 1-5
;
	IN	AL, PPI_C				; get expansion card memory size
			IF CPU_TYPE EQ CPU_V20
	ROR4	_DL					; DL(h) = bits 1-4 from AL
	XCHG	AX, CX				; AL = switches
	AND	AL, NOT MASK PBSW			; read SW2 5
	OUT	PPI_B, AL
	IN	AL, PPI_C				; read bit 5
	AND	AL, 0001B				; isolate memory size bit 5
	ROR4	_DL					; DL(h) = high bit, DL(l) = low 4
	SHL	DX, 5					; DX = blocks * 32
			ELSE
	AND	AL, 1111B				; isolate memory size (in 32KB)
	MOV	CH, AL				; save low 4 bits
	XCHG	AX, CX				; AL = switches, AH = low 4 bits
	AND	AL, NOT MASK PBSW			; read SW2 5
	OUT	PPI_B, AL
	IN	AL, PPI_C				; read bit 5
	AND	AL, 0001B				; isolate memory size bit 5
	MOV	CL, 4
	SHL	AL, CL				; shift into correct position
	OR	AL, AH				; combine with bits 1-4
	CBW						; clear AH
	INC	CX					; convert to KB (CL = 5)
	SHL	AX, CL				; AX = blocks * 32
	XCHG	AX, DX				; DX = expansion RAM in KB
			ENDIF

;----------------------------------------------------------------------------;
; Read motherboard RAM size from SW1 3-4
;
	IN	AL, PPI_A				; get drive, MB RAM, video
	PUSH	AX					; save SW1
	AND	AL, MASK PCMB			; isolate MB RAM
	ADD	AL, 4					; start at 16KB since SW1 00 = 16KB
	SHL	AX, 1					; AX = MB RAM size in KB
	SHL	AX, 1					; (AX = AX * 4)
	ADD	AX, DX				; add expansion RAM to total
	MOV	MEM_SZ_PC, AX			; save to BDA
	POP	AX					; restore SW1

		ELSE
		IF ARCH_TYPE EQ ARCH_FE2010
;----------------------------------------------------------------------------;
; Is a FE2010A PC
;
; Set AL for BDA / switch register
; Set AH for system config register
;
SETTINGS_FE2010:
	AND	AL, NOT MASK PBSW			; select register for PPI Bits 4-7
	OUT	PPI_B, AL				; port 61H Control Register
	AND	AL, MASK PBTB			; Turbo bit set?
	JZ	SETTINGS_FE2010_1			; jump if not turbo (AH already 0)
	MOV	AX, DBW <FE_CR <,,,,1,>>	; set AH default with FPU bit, clear AL
SETTINGS_FE2010_1:
	OUT	PPI_C, AL				; write 0 to port 62H Switch Register
	IN	AL, PPI_C				; port 62H Switch Register
			IF CPU_TYPE EQ CPU_V20
	SHL	AL, 4					; shift drives and video to high nibble
			ELSE
	MOV	CL, 4
	SHL	AL, CL				; shift drives and video to high nibble
			ENDIF
	AND	AL, MASK VID			; Bits 4-5 Video only
	OR	AL, EQFLAGS <,,,,,SW1_FLP AND 1,,,1>; set FPU: 1, defaults and SW1_FLP
							;   FD: 00b=1 drive, 01b=2 drives

		ELSE                          ; not ARCH_5150 OR ARCH_FE2010
		IF ARCH_TYPE EQ ARCH_EHB OR ARCH_TYPE EQ ARCH_BOOK88 OR ARCH_TYPE EQ ARCH_CPQ
		;IF ARCH_TYPE EQ ARCH_EHB OR ARCH_TYPE EQ ARCH_BOOK88
		; TODO: better way to force DIP switches
;----------------------------------------------------------------------------;
; System has no DIP switches - use default and specified settings
;
	MOV	AL, LOW EQFLAGS <,,,,,SW1_FLP,SW1_VID>	; use preconfigured values

		ELSE
;----------------------------------------------------------------------------;
; Is a 5160 or standard PPI
;
SETTINGS_5160:
	AND	AL, NOT MASK PBSW			; set bit 3 = 0 for low switch select
	OUT	PPI_B, AL
	PUSH	AX		 			; save port settings
	IN	AL, PPI_C 				; get low switches
			IF CPU_TYPE	EQ CPU_V20
	ROR4	_CL					; CL(h) = PPI low switches
			ELSE
	AND	AL, MASK MBRAM OR MASK FPU OR MASK IPL ; isolate MB RAM and FPU bits
	MOV	CH, AL				; save to CH
			ENDIF
	POP	AX 					; get port settings
	OR	AL, MASK PBSW 			; set bit 3 = 1 for high switch select
	OUT	PPI_B, AL
	IN	AL, PPI_C 				; get high switches
			IF CPU_TYPE	EQ CPU_V20
	ROR4	_CL					; CL(h) = PPI high, CL(l) = PPI low
	XCHG	AX, CX				; AL = RAM, FPU with drives and vid
			ELSE
	MOV	CL, 4
	SHL	AL, CL				; shift drives and video to high nibble
	OR	AL, CH				; combine RAM, FPU with drives and vid
			ENDIF

			IF MAX_RAM_AUTO EQ 1
;----------------------------------------------------------------------------;
; Set MAX_RAM from video DIP switches: CGA=736, MDA=704 else 640
; 21 bytes
;
MAX_RAM_AUTO_SETUP PROC
	PUSH	AX					; save original equipment byte
	MOV	DX, MAX_RAM_PC			; default 640K
	AND	AL, MASK VID			; bits 4-5 video only
	JZ	MAX_RAM_AUTO_DONE			; done if EGA/VGA (OFF, OFF)
	MOV	DL, LOW MAX_RAM_MDA		; try MDA 704K
	CMP	AL, VID_MDA SHL VID		; is MDA (ON, ON)?
	JE	MAX_RAM_AUTO_DONE			; done if MDA
	MOV	DL, LOW MAX_RAM_CGA		; else CGA 736K
MAX_RAM_AUTO_DONE:
	MOV	MEM_SZ_PC, DX			; save to BDA
	POP	AX					; restore equipment byte
MAX_RAM_AUTO_SETUP ENDP
			ENDIF

		ENDIF					; not ARCH_TYPE EQ ARCH_EHB
		ENDIF					; not ARCH_TYPE EQ ARCH_FE2010
		ENDIF					; not ARCH_TYPE EQ ARCH_5150

SETTINGS_DONE:
;----------------------------------------------------------------------------;
; If set on MB DIP SW1, test and verify FPU. If not detected, disable in BDA.
;
	TEST	AL, MASK FPU			; is FPU set?
	JZ	SETTINGS_SAVE			; if not, skip to save flags
	CALL	HAS_FPU				; check FPU, ZF=0 if not detected
	JZ	SETTINGS_SAVE			; if detected, save flags
			IF ARCH_TYPE EQ ARCH_FE2010
	AND	AX, NOT DBW <MASK FFPU, MASK FPU> ; otherwise clear FPU flags
			ELSE
	AND	AL, NOT MASK FPU			; otherwise clear FPU flag
			ENDIF
SETTINGS_SAVE:
	MOV	BYTE PTR EQUIP_FLAGS, AL	; set to low byte of EQUIP_FLAGS

			IF ARCH_TYPE EQ ARCH_FE2010
;----------------------------------------------------------------------------;
; Write to FE2010A switch registers
;
	OUT	PPI_C, AL				; write to switch register
	XCHG	AH, AL
	CALL	FE2010_SETUP_SAVE			; save to memory and register
	XCHG	AH, AL
	CBW						; clear AH (cannot have > 2 FDs)
			ENDIF

	XCHG	AX, DX				; save EQUIP_FLAGS to DL for later
	POP	AX					; AL = original settings, AH = 0
	OUT	PPI_B, AL				; restore original settings

			IF ARCH_SUB_TYPE EQ ARCH_VEN888
;----------------------------------------------------------------------------;
; Set initial speed for Vendex 888-XT
;
	CALL	TOGGLE_TURBO			; set speed according to PPI (reversed)
			ENDIF

			IF ARCH_TYPE EQ ARCH_TD3300
			IF TD_WS_SETUP EQ 1
;----------------------------------------------------------------------------;
; Set up TD3300A wait state register. This sequence is the "magic incantation"
; to set the TD3300 chipset wait state configuration.
;
	;CLI					; disable interrupts (already off)
	IN	AL, TD_WS			; read and throw away
	MOV	AL, TD_WS_R			; set new default POST wait states
	OUT	TD_WS, AL			; write to register
	STI					; write two STIs for TD3300 to accept
	STI
	CLI					; interrupts should be off
			ENDIF
			ENDIF

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
	GET_EFLAG  VID				; AX = 00=error(ZF), 01=CGA 40, 10=CGA 80, 11=MDA
	JNZ	VID_MODE_OK				; jump if mode valid or video option ROM loaded
	MOV	BL, BEEP_SL <3,3>			; Beep 3 long, 3 short
HALT_BEEP_2:
	JMP	HALT_BEEP				; NEAR jump to beep
VID_MODE_OK:
	TEST	DL, MASK VID			; is SW1 mode 00?
	JZ	RESET_VIDEO_DONE			; if custom video ROM, skip reset
	MOV	BX, OFFSET VID_MODE_TBL[-1]	; AL = BDA video type, BX = mode table
	XLAT	CS:[BX]				; AL = INT 10H video mode

;----------------------------------------------------------------------------;
; Clear screen and reset the video display
;
RESET_VIDEO:
	INT	10H					; AH = 0 - Set Video Mode
RESET_VIDEO_DONE:

			IF POST_BANNER EQ 1
;----------------------------------------------------------------------------;
; Hello Computer ("just use the keyboard")
;----------------------------------------------------------------------------;
HELLO_WORLD:
			IF RANDOM_TAGLINE EQ 1
	CALL	HELLO_RAND_TAGLINE		; display banner and random tagline
			ELSE
	PRINTLN_SZ	TOP_BANNER			; display banner and fixed tagline
			ENDIF
			ENDIF

;----------------------------------------------------------------------------;
; Save the initial cursor mode to BDA for hot key and POST display
;
	XOR	BX, BX				; BH = video page 0
	MOV	AH, 3					; get cursor: CX = power-on cursor
	INT	10H					;  DX = position
	MOV	CURSOR_DEFAULT, CX		; save to BDA for Turbo toggle

			IF POST_BANNER EQ 1
;----------------------------------------------------------------------------;
; Display VERSION notice in bottom left
;
	PUSH	DX					; save cursor position
	MOV	DX, DBW <24, 0> 			; bottom left row = 24, col = 0
	MOV	AH, 2 				; set bottom cursor position 
	INT	10H 					; row = DH, column = DL
	PRINT_SZ  VER				; display version
	PRINT_SZ  REL_DATE			; display build date
	POP	DX					; restore previous cursor
	MOV	AH, 2 				; reset cursor position
	INT	10H 					; row = DH, column = DL
			ENDIF

;----------------------------------------------------------------------------;
; Jump over INT 02h fixed ORG to continue...
;
		IF ARCH_TYPE EQ ARCH_TD3300
	JMP	SHORT POST_DETECT_PORTS
		ELSE
	JMP	NEAR PTR POST_DETECT_PORTS
		ENDIF

			IF IS_TURBO
;----------------------------------------------------------------------------;
; Toggle Turbo mode on/off
;----------------------------------------------------------------------------;
; Note: for standard PPI-based systems, some references state that flipping
; both bit 2 and 3 (0Ch) are required, and some only bit 2 (04h). Flipping 
; only bit 2 seems to work fine however.
;
; Clobbers AX, CX, DX
;----------------------------------------------------------------------------;
TOGGLE_TURBO PROC
			ASSUME DS:_BDA
	CLI						; interrupts off

		IF ARCH_TYPE EQ ARCH_TD3300
			IF ARCH_SUB_TYPE NE ARCH_NEST
;----------------------------------------------------------------------------;
; TD3300A Port 90h Turbo switch
; If port 90 == 1, send 2 (0010b) Normal -> Turbo
; If port 90 == 0, send 3 (0011b) Turbo -> Normal
;
	IN	AL, TD_TURBO			; read current state
	CMP	AL, MASK TDSS			; is 1 or 0?
	JA	TOGGLE_TURBO_DONE			; exit if register not valid
	JZ	TOGGLE_TURBO_TD_1			; jump if 1 (currently Turbo)
	OR	AL, MASK TDSH			; set software speed bit
TOGGLE_TURBO_TD_1:
	XOR	AL, MASK TDSS			; toggle turbo bit
	OUT	TD_TURBO, AL			; write to board
	CMP	AL, MASK TDSH OR MASK TDSS	; turbo on? (NZ = turbo)

			ELSE
;----------------------------------------------------------------------------;
; D-11 Turbo toggle
; Bit 1 (D11SF) is used to keep state of current speed, since software-set
; speed is not readable. XOR software-controlled speed bit (D11SS) with speed
; flag big (D11SF) and flip.
;
	IN	AL, N3_CTRL
	OR 	AL, MASK D11SX			; set speed bit
	MOV	AH, AL				; save state bit
	SHR	AH, 1					; shift to low bit
	AND	AH, MASK D11SS			; isolate speed bit
	XOR	AL, AH				; flip if needed
	XOR	AL, MASK D11SF			; flip flag
	OUT	N3_CTRL, AL
	TEST	AL, MASK D11SF			; turbo on? (NZ = turbo)
			ENDIF				; NOT ARCH_NEST
		ELSE					; NOT ARCH_TD3300

;----------------------------------------------------------------------------;
; VTech Laser Turbo XT switch
; Only bit 7 is used, 0 for standard speed and 1 for turbo speed
;
			IF ARCH_TYPE EQ ARCH_LASER
	MOV	DX, LASER_TURBO			; store speed control port
	IN	AL, DX				; read current state
	XOR	AL, MASK LASER_SPD		; flip turbo bit
	OUT	DX, AL				; write to speed control port
			ELSE				; NOT ARCH_TD3300 OR ARCH_LASER

;----------------------------------------------------------------------------;
; Standard PPI B Turbo switch
;
	IN	AL, PPI_B				; read PPI
	XOR	AL, MASK PBTB			; flip turbo bit
	OUT	PPI_B, AL

				IF ARCH_TYPE EQ ARCH_FE2010
;----------------------------------------------------------------------------;
; FE2010 Toggle two speeds
;
	XCHG	AX, CX				; save AX
	MOV	AL, FE2010_CONF_REG		; get current register
	XOR	AL, FE_CR <> AND MASK FSPD	; flip speed bit(s)
	CALL	FE2010_SETUP_SAVE			; write to memory and register
	XCHG	AX, CX				; restore AX
				ENDIF			; ARCH_FE2010

				IF ARCH_TYPE EQ ARCH_UM82
;----------------------------------------------------------------------------;
; UM82C088 speed mode
;
	OUT	UM82_SPEED, AL			; write any value to toggle speed
				ENDIF			; ARCH_UM82

				IF ARCH_SUB_TYPE EQ ARCH_VEN888
;----------------------------------------------------------------------------;
; Vendex 888-XT
; For turbo: Write 3 then 1 to 0C0H
; For slow:  Write 2 then 1 to 0C0H
;----------------------------------------------------------------------------;
; Input:
;	Turbo: AL = xxxxx1xx	-> 3 (0011)
;	Slow:  AL = xxxxx0xx	-> 2 (0010)
;
	AND	AL, MASK PBTB			; AL = 4 (NZ) if turbo, 0 (ZF) if slow
	XCHG	AX, CX				; save original turbo bit
	MOV	AL, 3					; AL = 3 - assume turbo
	JNZ	VEN888_TURBO
	DEC	AX					; AL = 2 - speed normal
VEN888_TURBO:
	OUT	0C0H, AL				; write speed
	MOV	AL, 1					; software select bit
	OUT	0C0H, AL				; write bit
	XCHG	AX, CX				; restore original turbo bit
				ENDIF

				IF ARCH_TYPE EQ ARCH_EHB
;----------------------------------------------------------------------------;
; EMM Homebrew/V40 - Toggle wait state FF = 3 W/S, 0 = zero W/S
;
	MOV	DX, V40_WCR1			; V40 wait state register
	IN	AL, DX				; read current register
	NOT	AL					; toggle FF to 0
	OUT	DX, AL				; write register
	NOT	AL					; revert since NZ is Turbo
				ENDIF			; ARCH_EHB

				IF (ARCH_TYPE EQ ARCH_EMU) AND (ARCH_SUB_TYPE EQ ARCH_MIST)
;----------------------------------------------------------------------------;
; PCXT_MiSTer - Toggle between 4 MHz AT and 5MHz XT
;
	MOV	DX, MC_PORT				; DX = XTCTL port
	IN	AL, DX				; read current speed
	AND	AL, NOT MCSP_LOW			; clear high bit (if set by XTCTL)
	XOR	AL, MCSP_TOG			; toggle speed bits
	OUT	DX, AL				; set new speed
	TEST	AL, MASK MCAT4			; high speed bit set?
				ELSE			; NOT ARCH_MIST AND NOT ARCH_TD3300

;----------------------------------------------------------------------------;
; NZ if turbo bit set, ZF if not turbo
;
;					IF ARCH_TYPE EQ ARCH_FE2010
;	TEST	AL, MASK FSPD			; speed low?
;					ELSE
	TEST	AL, MASK PBTB			; standard turbo bit set?
;					ENDIF
				ENDIF			; ARCH_MIST
			ENDIF				; ARCH_LASER
		ENDIF					; ARCH_TD3300

	MOV	CX, CURSOR_DEFAULT		; original power-on cursor (fast)
	JNZ	TOGGLE_TURBO_CURSOR		; Jump if turbo, use original cursor
	XOR	CH, CH 				; starting scan line 0 ("big cursor")
TOGGLE_TURBO_CURSOR:
	CALL	SET_CURSOR				; Video set cursor

TOGGLE_TURBO_DONE:
	STI						; Enable interrupts
	RET
TOGGLE_TURBO ENDP
			ENDIF				; IF IS_TURBO

			IF ARCH_TYPE EQ ARCH_TD3300
			IF TD_UPMEM EQ 1
;----------------------------------------------------------------------------;
; TD3300A: Set up, check and clear upper memory bank on cold boot
;----------------------------------------------------------------------------;
; On cold boot, if DIP switches select 1024K of installed RAM, the upper bank
; is written to clear parity bits. This is normally not necessary since
; software utilizing that RAM must do that before using it.
;
; The RAM between 128k-512k is bank switched to the upper bank and then
; cleared by resetting the currently tested and end address offsets.
;
; Note: whether the the bank was actually switched is not checked so as long
; as the RAM check passes and DIP switches are set for 1024K (on-on), it will
; appear to count up to 1024K. It is left to the software to verify that the
; bank switching is functioning.
;
; Note 2: this is called twice from DETECT_MEMORY. Once after completion of
; the low memory, and once after the completion of the TD3300A upper bank.
; SI is used to determine which call is being made, so it must be preserved
; between calls.
;
; Input: (required)
;	SI = on first call: sign bit set (from POST_MEMORY string offset)
;----------------------------------------------------------------------------;
TD3300_MEM_CLEAR PROC

			IF ARCH_SUB_TYPE NE ARCH_NEST
;----------------------------------------------------------------------------;
; TD3300A implementation
;----------------------------------------------------------------------------;
	XOR	AX, AX				; ensure AL is 0
	OUT	TD_MEM, AL				; switch to lower bank (AL=0)
	TEST	SI, SI				; done clearing TD high memory?
	JS	TD3300_MEM_CLEAR_HI		; if SI sign bit, clear high bank
TD_DONE_ZERO_ALL_RAM:
	JMP	NEAR PTR TD_MEM_CLEAR_DONE	; return, RAM test complete

;----------------------------------------------------------------------------;
; Only clear RAM if DIP switches set for 1 MB
;
TD3300_MEM_CLEAR_HI:
	XCHG	AX, SI				; save AX
	CMP_EFLAG  MBRAM, 11B			; ZF if DIP set for 1MB
	CBW						; AH = 0 (clear SI sign bit)
	XCHG	AX, SI				; restore AX, SI high bit = 0
	JNE	TD_DONE_ZERO_ALL_RAM		; if not 1MB, RAM test complete
	JWB	TD3300_NO_CLEAR			; if warm boot, count but don't clear

;----------------------------------------------------------------------------;
; Enable bank 1, reset start address to 2000H and end address to 8000H
;
	INC	AX					; TD_MEM_CR <,1>
	OUT	TD_MEM, AL				; switch to upper bank
	MOV	AX, KBP < 128 >			; restart at segment 2000H (128K)
	MOV	DH, HIGH KBP < 512 >		; end at segment 8000H (512K)
	JMP	NEAR PTR ZERO_ALL_RAM_1		; continue RAM test

;----------------------------------------------------------------------------;
; Don't clear upper RAM on warm boot if DIP switches set for 1024K.
;
TD3300_NO_CLEAR:
	MOV	BX, 1024 - 16			; fake 1024K display count
	JMP	NEAR PTR ZERO_ALL_RAM		; display RAM count and exit test

			ELSE
;----------------------------------------------------------------------------;
; D-11/Nest implementation. Swap each 64K bank into E000, clear and test.
;----------------------------------------------------------------------------;
	MOV	AX, SI				; AL = current page to test (0AH-0FH)
	CMP	AL, 0FH				; past last page?
	JA	TD_DONE_ZERO_ALL_RAM		; exit if done
	OUT	N3_MEM, AL 				; select next UMA page

;----------------------------------------------------------------------------;
; On Nest, Motherboard RAM select DIP switches are not connected to PPI so
; upper RAM size must instead be detected.
;
	PUSH	BX					; preserve BX
	MOV	AX, 0E000H				; first, address line test
	MOV	ES, AX				; Test 16K segment at ES:0
	CALL	MEM_ADDR_TEST			; test if RAM installed, ZF if so
	POP	BX
	JNZ	TD_DONE_ZERO_ALL_RAM		; exit if RAM not detected

	INC	SI					; next page
	MOV	AX, ES				; AX = window at segment E000H
	MOV	DH, HIGH 0F000H			; end at segment F000H
	JMP	NEAR PTR ZERO_ALL_RAM_1		; continue RAM test
TD_DONE_ZERO_ALL_RAM:
	JMP	NEAR PTR TD_MEM_CLEAR_DONE	; return, RAM test complete
			ENDIF				; END NE ARCH_NEST
TD3300_MEM_CLEAR ENDP
			ENDIF				; END EQ TD_UPMEM
			ENDIF				; END EQ ARCH_TD3300

			IF ARCH_TYPE EQ ARCH_FE2010
;----------------------------------------------------------------------------;
; Initial Set up Memory and lock Configuration Register
;----------------------------------------------------------------------------;
; Input:
;	DX = highest memory segment detected
; 	FE2010_CONF_REG set for 640K
;
; AX clobbered
;----------------------------------------------------------------------------;
FE2010_SETUP_MEM PROC
	MOV	AL, FE2010_CONF_REG		; get register
			IF FE_CONF_LOCK EQ 1
	OR	AL, MASK FLCK			; lock config until reboot
			ENDIF
	CMP	DH, HIGH KBP < 512 >		; is memory size 8000H? (512K)
	JA	FE2010_SETUP_OUT			; is > 512K (already set for 640K)
	MOV	AH, MASK FME1			; set for 512K
	JE	FE2010_SETUP_SET			; is 512K, set to 512K
	MOV	AH, MASK FME2			; else set for 256K
FE2010_SETUP_SET:
	OR	AL, AH				; set bits if not 640K

;----------------------------------------------------------------------------;
; Write AL to memory and control register
;
FE2010_SETUP_SAVE PROC
	MOV	FE2010_CONF_REG, AL		; save register to memory
FE2010_SETUP_OUT:
	OUT	PPI_CW, AL				; write to config register
	RET
FE2010_SETUP_SAVE ENDP

FE2010_SETUP_MEM ENDP
			ENDIF

			IF ARCH_TYPE EQ ARCH_UM82
;----------------------------------------------------------------------------;
; Read UM82 memory size
;----------------------------------------------------------------------------;
; Output: CX = memory in # of 16K blocks above the first 16K block
;----------------------------------------------------------------------------;
UM82_IS_512	= NOT UM82_512K AND MASK U8MEM
UM82_IS_640	= NOT UM82_640K AND MASK U8MEM
UM82_MEM_SIZE PROC
	IN	AL, UM82_STATUS			; read UM82 status
	MOV	CX, 40 - 1				; 40 * 16K = 640K
	TEST	AL, UM82_IS_640			; is 640K?
	JE	UM82_DONE				; if so, done
	MOV	CL, 32 - 1				; 32 * 16K = 512K
	TEST	AL, UM82_IS_512			; is 512K?
	JE	UM82_DONE				; if so, done
	MOV	CL, 16 - 1				; 16 * 16K = 256K
UM82_DONE:
	RET
UM82_MEM_SIZE ENDP
			ENDIF

			IF INIT_V40 EQ 1 OR INIT_AT_KBC EQ 1
;----------------------------------------------------------------------------;
; Cold boot hardware init
;----------------------------------------------------------------------------;
; Set up any special hardware that must be initialized at power on.
;----------------------------------------------------------------------------;

			IF INIT_V40 EQ 1
;----------------------------------------------------------------------------;
; V40 PC register initialization table
; Format: data byte, low byte of register port (high byte is FF)
;
V40_INIT_OPTIONAL	= 0		; init optional unused registers
V40_REG LABEL BYTE
	DB	00000000B,	0FEH 	; FFFE: OPCN - INT Select
	DB	00000110B,	0FDH 	; FFFD: OPSEL - Enable TCU/ICU, Disable DMAU/SCU
					;	Only Enable The Interrupt Controller And Timer
	DB	00H, 		0FCH	; FFFC: OPHA - On-chip Peripheral High Address Register
					;	Any 256K Block Except Overlap with Registers
			IF V40_INIT_OPTIONAL EQ 1
	DB	00000000B,	0FBH	; FFFB: DULA - DMA Lower Address Register
			ENDIF
	DB	00100000B,	0FAH	; FFFA: IULA - 8259 Lower Address Register
	DB	01000000B,	0F9H 	; FFF9: TULA - 8254 Lower Address Register
			IF V40_INIT_OPTIONAL EQ 1
	DB	11010000B,	0F8H 	; FFF8: SULA - Serial Port Lower Address Register
			ENDIF
	DB	00000000B		; FFF6: WCY2 - Number of wait cycles for DMA and refresh
	DB	LOW V40_WCR2	;	00 seems safe for SRAM since no refresh happens
			IF NOT PPI_B_BOOT AND MASK PBTB 	; Boot to Turbo/0-WS speed?
	DB	V40_WCY1<0,0,0,0>	;	WCY1 - All Zero wait state
			ELSE
	DB	V40_WCY1<3,3,3,3>	;	WCY1 - 3 W/S everywhere
			ENDIF
	DB	LOW V40_WCR1	; FFF5: WCY1 - WAIT Wait bits 7-6 = IO, 5-4 = Upper Mem,
					;	3-2 = Middle Mem, 1-0 Lower Mem
					;	0FFH: Super conservative: 3WS everywhere
					;	025H: Bolder: Zero wait-state I/O
					;	 00H: Full Zero wait state, best performance
	DB	00000110B,	0F4H 	; FFF4: WMB - Memory Boundaries
					;	Bits 6-4 are size of "high" memory, 2-0 "low"
					;	in 32k units.  Default puts bottom 32k "low"
					;	and above 640k in "high" for stuff like slow
					;	video cards and option BIOSes
	DB	00H,		0F2H	; FFF2: RFC - Refresh Control
					;	00 (disabled refresh) for SRAM
			IF V40_INIT_OPTIONAL EQ 1
	DB	00010100B,	0F0H 	; FFF0: TCKS - Timer Pin Selection
			ELSE
	DB	00011100B,	0F0H 	; FFF0: TCKS - Timer Pin Selection
			ENDIF
					; 	Bits 4-2 set sources for timers (1 for TCLK)
					;	1=Pin, 0=internal, Bits 1-0 Prescale Div For Internal
L_V40_REG	=	($-V40_REG)/2
			ENDIF		; /IF INIT_V40 EQ 1

COLD_INIT PROC

			IF INIT_V40 EQ 1
;----------------------------------------------------------------------------;
; V40 Compatibility Register Setup
;----------------------------------------------------------------------------;
; Contributed by @Hak Foo
;----------------------------------------------------------------------------;
SETUP_V40 PROC
	MOV	CX, L_V40_REG		; counter = size of V40_REG
	MOV	SI, OFFSET V40_REG	; register data
	MOV	DH, 0FFH			; high byte of DX is always FF
V40_REG_LOOP:
	LODS	WORD PTR CS:[SI]		; AH = low byte of reg, AL = reg value
	MOV	DL, AH			; DX = next register
	OUT	DX, AL			; write to register
	LOOP	V40_REG_LOOP
SETUP_V40 ENDP
			ENDIF

			IF INIT_AT_KBC EQ 1
;----------------------------------------------------------------------------;
; AT / 8042 Keyboard reset
;
SETUP_AT_KBC PROC
	MOV	AL, 0AAH		; Test Controller
	OUT	ATKB_CMD, AL	; OUT Command Port (64h)
	IO_DELAY
	IN	AL, ATKB_IO		; Read Data Port and discard (60h)

	MOV	AL, 01100000B	; Write Command Byte to Keyboard Controller
	OUT	ATKB_CMD, AL	; OUT Command Port (64h)
	INC	AX			; PC Mode, Enable Interrupt (01100001b)
	OUT	ATKB_IO, AL		; OUT Data Port (60h)
SETUP_AT_KBC ENDP
			ENDIF

;----------------------------------------------------------------------------;
; Done with COLD_INIT - continue POST
;
	JMP	COLD_INIT_DONE	; continue POST

COLD_INIT ENDP
			ENDIF

			IF FD_AUTO_DETECT EQ 1
;----------------------------------------------------------------------------;
; Set BDA Floppy disk count in to AL
;----------------------------------------------------------------------------;
SET_EFLAG_FLP PROC
	TEST	AX, AX				; zero drives found?
	JZ	SHORT SET_EFLAG_FLP_RET		; don't change BDA (no option for 0)
	PUSH	AX
	DEC	AX					; adjust 0-based count
	AND	AL, SW1_FLP				; max number of drives
	SET_EFLAG  FLP				; set floppy count
	POP	AX
SET_EFLAG_FLP_RET:
	RET
SET_EFLAG_FLP ENDP
			ENDIF

;
; 8 BYTES HERE
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
	PUSH	AX
	IN	AL, PPI_C 				; get PC0 register
	TEST	AL, MASK PCPE OR MASK PCIE	; parity or I/O error?
	JNZ	INT_02_NMI_PAR 			; first, check parity
	POP	AX					; if neither, exit
	IRET						; must have been an 8087 NMI
INT_02_NMI_PAR:
	MOV	SI, OFFSET NMI_ERR_PAR 		; Parity error string
	TEST	AL, MASK PCPE			; parity error?
	JNZ	INT_02_NMI_HALT
	DEC	SI					; otherwise is I/O error
	DEC	SI					; decrement to NMI_ERR_IO
INT_02_NMI_HALT:
			IF CPU_TYPE	EQ CPU_V20
	MOV	AL, OCW1 <1,1,1,1,1,1,1,1>	; mask the maskable since V20 can
	OUT	INT_IMR, AL				;  exit HLT on IRQ even if IF=0
			ENDIF
	XOR	AX, AX				; reset video, clear screen
	OUT	NMI_R0, AL				; mask the unmaskable
	INT	10H					; switch to text video mode
	CALL	OUT_SZ 				; display string in CS:SI
	CALL	NMI_RESET				; clear NMI/parity flags
	CLI						; ensure interrupts off
	HLT						; halt CPU
INT_02 ENDP

POST_DETECT_PORTS PROC
;----------------------------------------------------------------------------;
; [37] Setup LPT/COM default timeouts
;----------------------------------------------------------------------------;
			ASSUME ES:_BDA
	MOV	DI, OFFSET LPT_TIME
	MOV	AX, DBW <LPT_TO, LPT_TO>	; LPT timeout values
	STOSW						; write x 4 to BDA
	STOSW
	MOV	AX, DBW <COM_TO, COM_TO>	; COM timeout values
	STOSW
	STOSW

	MOV	BX, OFFSET EQUIP_FLAGS[1]	; BX = high byte of EQUIP_FLAGS

;----------------------------------------------------------------------------;
; [38] Detect and enable Game port
;----------------------------------------------------------------------------;
; Port 201H
; Input: 
;	BX = high byte of EQUIP_FLAGS
;
; Equipment Bit is set if the lower nibble of an I/O port 201h read is zero
; http://www.minuszerodegrees.net/5150_5160/post/IBM%205150%20and%205160%20-%20Bit%2012%20of%20Equipment%20Flag.htm
;----------------------------------------------------------------------------;
POST_DETECT_GAM:
	MOV	DX, GAME_CTRL
	IN	AL, DX 				; will be 0FFH if no port
	TEST	AL, 0FH
	JNZ	NO_GAME_PORT
	OR	BYTE PTR [BX], HIGH MASK GAM	; enable Game Port bit
NO_GAME_PORT:

;----------------------------------------------------------------------------;
; [37] Detect and enable COM ports 1-4
;----------------------------------------------------------------------------;
; Ports 3F8H, 2F8H, 3E8H, 2E8H
; Input:
;	BX = high byte of EQUIP_FLAGS
;	ES, DS = BDA segment
;----------------------------------------------------------------------------;
POST_DETECT_COM:
	MOV	CX, 4					; four COM ports
	XOR	DI, DI 				; 00H BDA COM1-4 base addresses
	MOV	DX, COM1_IIR			; 3FAH: COM1 Interrupt Ident Reg
COM_DETECT_LOOP:
	XOR	AL, AL				; AL = 0
	OUT	DX, AL				; clear FIFO Control Register (FCR)
	IN	AL, DX 				; read IIR to clear DMA flags
	IN	AL, DX 				; read IIR again
	DEC	DX
	DEC	DX					; DX = base port
	TEST	AL, 11110000B 			; check if any high 4 bits are set
	XCHG	AX, DX				; AX = detected port
	JNZ	NO_COM_PORT				; if so, not a valid port
	STOSW 					; write I/O port to COM BDA table
	ADD	BYTE PTR[BX], HIGH(1 SHL COM)	; INC COM port count in flags
NO_COM_PORT:
	SUB	AX, COM1_DATA-COM2_IIR		; base port to next IIR port
	XCHG	AX, DX				; DX = next IIR port
	CMP	CL, 3 				; is COM2 (COM3 next)?
	JNE	NEXT_COM_PORT			; if not, next
	MOV	DX, COM3_IIR			; restart at 3EAH: COM3 IIR
NEXT_COM_PORT:
	LOOP	COM_DETECT_LOOP

;----------------------------------------------------------------------------;
; [36] Detect and enable LPT ports
;----------------------------------------------------------------------------;
; Ports 3BCH, 378H, 278H
; Input: 
;	BX = high byte of EQUIP_FLAGS
;	CH = 0
;----------------------------------------------------------------------------;
POST_DETECT_LPT:
	MOV	CL, 3					; three LPT ports
	MOV	DI, OFFSET LPT_ADDR		; 08H BDA LPT1-3 base addresses
	MOV	DX, LPT_MDA				; start with MDA printer base
LPT_DETECT_LOOP:
	MOV	AL, MASK LCDR OR MASK LCINI-1	; use init byte - 1 as test data
	OUT	DX, AL				; send to LPT data port
	INC	DX
	INC	DX					; DX = control port
	INC	AX					; AL = Strobe off / init (1100b)
	OUT	DX, AL				; send to LPT control port
	DEC	DX
	DEC	DX					; DX = data port
	IN	AL, DX				; read from LPT data port
	XOR	AL, MASK LCDR OR MASK LCINI-1	; valid port if same test data
	JNZ	NO_LPT_PORT				; if not, not a valid port
	XCHG	AX, DX				; AX = detected port
	STOSW 					; store to LPT BDA table
	XCHG	AX, DX
	ADD	BYTE PTR[BX], HIGH(1 SHL LPT)	; INC LPT port count in flags
NO_LPT_PORT:
	DEC	DH 					; DX = DX - 100H (LPT1-LPT2)
	CMP	CL, 3 				; is 3BCH (LPT1 next)?
	JNE	NEXT_LPT_PORT			; if not, next
	MOV	DX, LPT1				; restart at 378H: LPT1 data port
NEXT_LPT_PORT:
	LOOP	LPT_DETECT_LOOP

POST_DETECT_PORTS ENDP

		IF MUTE_TANDY EQ 1
;----------------------------------------------------------------------------;
; Mute Tandy 3 Voice Sound card (SN76489AN) buzzing on boot
;----------------------------------------------------------------------------;
	MOV	DX, 0C0H				; port can be 0C0H, 01E0H, 02C0H
			IRP	B, < 0FFH, 0BFH, 0DFH, 09FH >
	MOV	AL, B
	OUT	DX, AL
			ENDM
		ENDIF

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
	MOV	AL, KB_BUF_END_B			; (AH already 00)
	STOSW						; DI = KB_BUF_ST + 4

;----------------------------------------------------------------------------;
; Hold clock low 20+ ms to signal keyboard to reset. Clear and re-enable.
;
	MOV	AL, 30				; I/O delay for at least 20ms
	CALL	IO_DELAY_MS
	XCHG	AX, SI				; restore modified PPI port B

	OR	AL, MASK PBKB OR MASK PBKC	; keyboard enable clock and clear
	OUT	DX, AL				; send to PPI port B
	PUSH	CX					; give a little more time
	AND	AL, NOT MASK PBKB			; keyboard enable (clear low)
	OUT	DX, AL				; send to PPI port B

;----------------------------------------------------------------------------;
; Unmask KB interrupt IRQ1
;
	IN	AL, INT_IMR 			; get PIC Port 1 INT mask
	XCHG	AX, SI 				; SI = save previous INT mask
	MOV	AL, NOT MASK IRQ1			; unmask only keyboard interrupt
	OUT	INT_IMR, AL

;----------------------------------------------------------------------------;
; Check if reset scan code was received
;
; Temporary INT_09_POST interrupt will set 4000H flag on BP
; when IRQ1 is received with successful reset code of 0AAh
;
			IF POST_TEST_KB NE 0
	STI 						; enable interrupts
KB_RESET_TEST:
	IO_DELAY_SHORT				; give a little more time
	POST_FLAG_TEST  PKI			; KB test flag yet?
	LOOPZ	KB_RESET_TEST			; Loop until KB flag OR CX is 0 (timeout)
	CLI 						; disable interrupts again
	POST_FLAG_FLIP  PKI			; invert PKI flag: 1 = error, 0 = success
			ENDIF
	IO_DELAY_LONG 				; additional delay, CX = 0

;----------------------------------------------------------------------------;
; Ack scan code, clear keyboard again and check that no scan codes were received
;
	IN	AL, DX				; read PPI port B
	OR	AL, MASK PBKB OR MASK PBKC	; keyboard enable clock and clear
	OUT	DX, AL				; send to PPI port B
	POP	CX					; give a little more time
	AND	AL, NOT MASK PBKB			; keyboard enable (clear low)
	OUT	DX, AL				; send to PPI port B
	IO_DELAY					; delay for KBC, CX = 0
	IN	AL, PPI_A 				; check KB for extraneous key
			IF POST_TEST_KB NE 0	; all KB tests enabled?
			IF POST_TEST_KEY NE 0	; Key Stuck test enabled?
	TEST	AL, AL				; AL should be 0
	JZ	KB_HAPPY				; if so, KB is ready
	POST_FLAG_SET  PKEY			; otherwise set flag for keyboard error
			ENDIF				; end Key Stuck test
			ELSE
	POST_FLAG_CLR  PKI			; clear any KB error
			ENDIF

KB_HAPPY:
;----------------------------------------------------------------------------;
; Disable keyboard for rest of POST
;
	IN	AL, DX
	OR	AL, MASK PBKB OR MASK PBKC	; keyboard enable clock and clear
	OUT	DX, AL				; send to PPI port B

	XCHG	AX, SI 				; restore interrupt mask register
	OUT	INT_IMR, AL

;----------------------------------------------------------------------------;
; Set up the real INT 09H keyboard interrupt handler
;
			ASSUME ES:_IVT
	MOV	ES, CX 				; ES = IVT seg (CX is 0 from above)
	MOV	DI, OFFSET IVT_09 		; DI = INT 9H offset in IVT (24H)
	MOV	AX, OFFSET INT_09 		; Vector offset
	STOSW 					; replace in IVT

POST_KB_RESET ENDP

;----------------------------------------------------------------------------;
; Begin Hardware POST Test Results
;----------------------------------------------------------------------------;
	CALL	HIDE_CURSOR				; cursor movement is distracting

			IF POST_WARM_COLD EQ 1
;----------------------------------------------------------------------------;
; Display "WARM" or "COLD" boot
;----------------------------------------------------------------------------;
; Size: 38 bytes
;----------------------------------------------------------------------------;
POST_BOOT_TYPE PROC
	MOV	SI, OFFSET POST_BOOT		; BOOT string
	MOV	BL, POST_CLR_WARM			; attribute to warm color
	CALL	POST_START_COL_1			; display column label
							;  CX=POST_TAB_COL_I, SI=WARM string
	JWB	POST_BOOT_TYPE_OUT		; jump if warm boot
	MOV	BL, POST_CLR_COLD			; attribute to cold color
	MOV	SI, OFFSET POST_COLD		; COLD string
POST_BOOT_TYPE_OUT:
	CALL	OUT_SZ_ATTR				; write string with attribute
	CALL	POST_END_COL_NL			; end of column with NL and RET

POST_BOOT_TYPE ENDP
			ENDIF

;----------------------------------------------------------------------------;
; [17] Detect and test conventional memory
;----------------------------------------------------------------------------;
	CALL	DETECT_MEMORY			; detect and display memory count
			ASSUME ES:NOTHING		; ES clobbered by DETECT_MEMORY

			IF POST_TEST_DMA_TC0 EQ 1
;----------------------------------------------------------------------------;
; [27B] Verify that the 8237 DMA Channel 0 Terminal Count (TC 0) status bit 
; is on. This test is only done on a cold boot.
;----------------------------------------------------------------------------;
	JWB	DMA_STATUS_OK			; skip on warm boot
	IN	AL, DMA_CMD				; verify DMA status register
	TEST	AL, MASK TC0			; Channel 0 TC
	JNZ	DMA_STATUS_OK			; jump if zero reached
	POST_FLAG_SET  PDMA			; else mark in POST error flags
DMA_STATUS_OK:
			ENDIF

			IF POST_CONFIG EQ 1
;----------------------------------------------------------------------------;
; Display Additional Configuration Items such as COM/LPT, CPU, FPU, etc
;----------------------------------------------------------------------------;
	CALL	POST_SYS_CONFIG			; show CPU, FPU and ports
			ENDIF

	CALL	CRLF_SHOW_CURSOR			; CRLF and re-enable cursor

;----------------------------------------------------------------------------;
; Unmask IRQs for Timer (IRQ0), Keyboard (IRQ1) and Floppy (IRQ6)
;----------------------------------------------------------------------------;
	IN	AL, INT_IMR 			; get current OCW1/IMR register
	AND	AL, NOT (MASK IRQ6 OR MASK IRQ1 OR MASK IRQ0) ; unmask IR6, IR1, IR0
	OUT	INT_IMR, AL 			; send to A1 (Port 1)

;----------------------------------------------------------------------------;
; [28] Option ROM scan for other ROMs (storage, etc)
;----------------------------------------------------------------------------;
	MOV	AX, SEG _OPT_ROM			; start at 0C800H
	MOV	DI, OPT_ROM_END			; end below 0FE00H
	CALL	BIOS_ROM_SCAN			; scan for option ROMs, AL = 0

			IF ARCH_TYPE EQ ARCH_TD3300 AND ARCH_SUB_TYPE EQ ARCH_NEST
			IF TD_WS_SETUP EQ 1
;----------------------------------------------------------------------------;
; Set up Nest/D-11 running W/S configuation
;
	IN	AL, TD_WS			; read and throw away
	MOV	AL, TD_WS_RB		; set new default BOOT wait states
	OUT	TD_WS, AL			; write to register
	STI					; write two STIs for TD3300 to accept
			ENDIF
			ENDIF

;----------------------------------------------------------------------------;
; [31] Enable interrupts
;----------------------------------------------------------------------------;
	STI 						; Interrupts now enabled

			IF FDC_ENABLE EQ 1
;----------------------------------------------------------------------------;
; [30] Recalibrate and test seek the floppy drive
;----------------------------------------------------------------------------;
FDC_POST PROC
	CBW						; AH = reset (0)
	CWD						; DL = start at drive 0
			IF FDC_IPL_SW EQ 1
	TEST_EFLAG	IPL				; IPL switch (floppy installed) set?
	JZ	FDC_POST_TESTS_COL		; if not, skip floppy init/test
			ENDIF
	INT	13H					; Reset the controller
	JC	FDC_POST_CT_ERR			; jump if controller reset failed
	GET_EFLAG  FLP				; AX = # of floppy drives (0 based)
	INC	AX					; fixup for 1 based drive count

			IF POST_TEST_FD EQ 1
;----------------------------------------------------------------------------;
; Test FDC drives - seek on cold boot, recal on warm boot
;
	XCHG	AX, CX				; CX = number of floppy drives
FDC_POST_TESTS_DRV:
	MOV	DI, OFFSET FD_LAST_OP		; DI = FD_LAST_OP to use INT 13h PROCs
				IF POST_TEST_SEEK EQ 1
	CALL	FDC_RECAL_SEEK_TEST		; recal and seek test
				ELSE
	CALL	FDC_RECAL				; do a recal only
				ENDIF
	JC	FDC_POST_DRV_ERR			; jump if error
	INC	DX					; DL = next drive
	LOOP	FDC_POST_TESTS_DRV
	JMP	SHORT FDC_POST_TESTS_DONE	; tests successful
FDC_POST_DRV_ERR:					; POST: drive seek error
				IF FD_AUTO_DETECT EQ 0
	POST_FLAG_SET  PFSK			; mark in POST error flags
				ENDIF
	JMP	SHORT FDC_POST_TESTS_DONE	; end POST test at failed drive
	;LOOP	FDC_POST_TESTS_DRV		;  or continue to next drive

			ELSE				; No POST seek test
	JMP	SHORT	FDC_POST_TESTS_COL
			ENDIF				; /POST_TEST_FD EQ 1

FDC_POST_CT_ERR:					; POST: controller error
	POST_FLAG_SET  PFDC			; mark in POST error flags

			IF POST_TEST_FD EQ 1
	XOR	DX, DX				; DX = 0 drives detected
FDC_POST_TESTS_DONE:
	XCHG	AX, DX				; AX = drive count

				IF FD_AUTO_DETECT EQ 1
;----------------------------------------------------------------------------;
; Update BDA FD count based on successfully tested drives
;
	CALL	SET_EFLAG_FLP			; set drive count in AL
				ENDIF			; /FD_AUTO_DETECT EQ 1

			ENDIF				; /POST_TEST_FD EQ 1

FDC_POST_TESTS_COL:
				IF POST_FD_COUNT EQ 1
;----------------------------------------------------------------------------;
; Display FDC POST drive count column in AX
; TODO: re-arrange to display counts after drive list
;
	POST_COL_1  POST_FDD, POST_CLR_VAL2	; display FDC column label
	CALL	NIB_HEX				; display drive count value in AL
	POST_COL_END				;  NIB_HEX returns AL <= 46h
				ENDIF

FDC_POST ENDP
			ENDIF				; IF FDC_ENABLE

;----------------------------------------------------------------------------;
; Detect and show hard drive info
;----------------------------------------------------------------------------;
HDD_POST PROC
			IF POST_HD_CHECK EQ 1
	CBW						; AH = 0 reset
	MOV	DL, 80H				; reset C: (80H)
	INT	13H
	JC	HDD_POST_NONE			; if CF, no HD or reset failure

	MOV	DL, 80H
	CALL	GET_DISK_PARAMS			; return # HD's in DX
	JC	HDD_POST_NONE

			IF POST_HD_COUNT EQ 1
;----------------------------------------------------------------------------;
; Display HDD POST drive count column
;
			IF FDC_ENABLE EQ 1
	POST_COL_2	POST_HDD, POST_CLR_VAL2	; display HDD column label
			ELSE
	POST_COL_1	POST_HDD, POST_CLR_VAL2	; no FDC, display HDD in column 1
			ENDIF

	PUSH	DX					; save drive count
	XCHG	AX, DX				; AL = drive count
	CALL	NIB_HEX				; write as hex to console (clobs AX)
	POST_COL_END_NL				; end column
	POP	CX					; CX = drive count
	JCXZ	HDD_POST_DONE			; reset passed but 0 drives

			IF POST_HD_PARMS EQ 1
;----------------------------------------------------------------------------;
; Display HDD drive letter(s) and size(s)
;	
	MOV	DL, 80H				; start with drive 80H (C:)
HDD_POST_SHOW_LOOP:
	CALL	SHOW_DISK_PARAMS			; show drive letter and geometry
	INC	DX					; move to next drive
	LOOP	HDD_POST_SHOW_LOOP
	JMP	SHORT HDD_POST_DONE
			ENDIF				; ENDIF POST_HD_PARMS EQ 1
			ENDIF				; ENDIF POST_HD_COUNT EQ 1
HDD_POST_NONE:
			ENDIF				; ENDIF POST_HD_CHECK EQ 1
	CALL	CRLF
HDD_POST_DONE:
HDD_POST ENDP

;----------------------------------------------------------------------------;
; [39] Clear and enable I/O and parity NMIs
;----------------------------------------------------------------------------;
	CALL	NMI_RESET				; reset NMI flags

			IF RAM_PARITY EQ 1
ENABLE_NMI:
	MOV	AL, NMI <1>				; AL = enable NMI
	OUT	NMI_R0, AL				; write to controller
			ENDIF

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
	POST_FLAG_CLR  WARM, 1			; remove warm boot flag, NZ if error
	JZ	POST_OK				; if no errors, go ahead and boot

;----------------------------------------------------------------------------;
; Display any POST errors
;
POST_ERROR:
	PRINT_SZ  POST_ERR			; display "Post Error"
	MOV	AX, BP				; AX = POST error flags
	CALL	WORD_HEX				; display POST error value
	CALL	CRLF
	CALL	POST_ERROR_MSG			; display POST error messages, BP=0

			IF POST_ERR_WAIT GT 0
;----------------------------------------------------------------------------;
; Wait for the Any Key if there was an error
;
	CALL	MEEPMEEP				; alert that there was an error, CX=0
	PRINT_SZ  NL_ANY_KEY			; "Any key" string
	XCHG	AX, CX				; wait for key press (AH=0)
	INT	16H
	CALL	CRLF					; move to next line
			ENDIF

POST_OK:
;----------------------------------------------------------------------------;
; Clear screen (partially or completely) and attempt boot
;
CLEAR_POST_SCREEN:
	MOV	BH, 7					; attribute fill for on blank line
			IF POST_CLS EQ 1		; clear the whole screen
	MOV	AX, DBW <7, 25>			; AH = 7, scroll down 25 lines
	MOV	CX, DBW <0, 0>			; upper left row 0, column 0
			ELSE				; clear only the lower two rows
	MOV	AX, DBW <7, 2>			; AH = 7, scroll down 2 lines
	MOV	CX, DBW <23, 0>			; upper left row 23, column 0
			ENDIF

	MOV	DX, DBW <25, 80>			; lower right row 25, column 80
	INT	10H

			IF POST_CLS EQ 1		; set cursor to top of screen
	MOV	AH, 2					; set cursor position
	MOV	BH, 0					; video page 0
	CWD						; row = 0, col = 0
	INT	10H
			ENDIF

	CALL	BEEP 					; beep to signify POST test is done
			IF POST_GLADOS EQ 1
	PRINT_SZ  BOOT_BEGIN			; Starting DOS...
			ELSE
	CALL	CRLF
			ENDIF

;----------------------------------------------------------------------------;
; [40] DO BOOTSTRAP!
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; Attempt to IPL three times. If failure, call INT 18h / ROM BASIC.
; If INT_19_BOOT_HD is 1, BIOS will also attempt to IPL from 80h (C:)
;

	CWD						; start IPL from drive 00h (A:)
BOOT_DEVICE:
	MOV	CX, 3 				; retry three times
BOOT_RETRY:
	PUSH	CX					; save retry counter
			IF INT_19_BOOT_HD EQ 1
	PUSH	DX					; save drive number
			ENDIF
	INT	19H
	IO_DELAY_LONG				; delay between attempts
			IF INT_19_BOOT_HD EQ 1
	POP	DX					; restore drive number
			ENDIF
	POP	CX					; restore retry counter
	LOOP	BOOT_RETRY
			IF INT_19_BOOT_HD EQ 1
	XOR	DL, 80H				; flip to HD
	JNZ	BOOT_DEVICE				; retry if HD, otherwise INT 18
			ENDIF

TRY_INT_18:
	INT	18H					; Try vectored ROM BASIC or boot failure
							; INT 18h should never return...
							;  fall through just in case

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
	PRINT_SZ  BOOT_FAIL			; print boot failure string
	XOR	AX, AX				; AH = 0 (wait for key)
	INT	16H					; wait for key press
	JMP	BOOT					; reboot
INT_18 ENDP

BOOT ENDP

;----------------------------------------------------------------------------;
;
; END OF BIOS POST/BOOTSTRAP
;
;----------------------------------------------------------------------------;

		ASSUME DS:_BDA
STRINGS PROC

BANNER_STRINGS PROC
;----------------------------------------------------------------------------;
; Banner Strings
;
					IF POST_GLADOS EQ 1
BOOT_BEGIN		DB	CR, LF
			DB	'Starting GLaDOS...'
NL2_Z			DB	LF				; two NL's, null term'd
					ENDIF
NL_Z			DB	CR, LF, 0			; one NL, null term'd
BOOT_FAIL		DB	'Disk Boot Fail.'
			DB	' You monster.'
NL2_ANY_KEY		DB	LF
NL_ANY_KEY		DB	CR, LF
ANY_KEY		DB	'Press the Any Key...'
			DB	 0
BANNER_STRINGS ENDP

POST_STRINGS PROC
;----------------------------------------------------------------------------;
; POST Test Strings
;
POST_CPU		DB	'CPU',  0			; 'CPU' followed by default
					IF ARCH_SUB_TYPE EQ ARCH_NEST
			DB	'8086', 0			;  *must be after POST_CPU
					ELSE
			DB	'8088', 0			;  *must be after POST_CPU
					ENDIF
POST_FPU		DB	'FPU',  0			; 'FPU' followed by default
			DB	'8087', 0			;  *must be after POST_FPU
POST_HD		DB	':',    0			; HD size letter display
			DB	' ', POST_M_UNIT		;  MB or MiB units display
			DB	0				;  *must be after POST_HD
POST_MEMORY		DB	'RAM',  0			; RAM Memory test
					IF RAM_DIGITS GT 3
			DB	'0'				; add extra 0 to RAM count
					ENDIF
			DB	'000 ', POST_K_UNIT	;  and KB or KiB
			DB	' OK',  0
					IF ARCH_SUB_TYPE EQ ARCH_NEST
POST_V20		DB	'V30'
					ELSE
POST_V20		DB	'V20'
					ENDIF
					IF INIT_V40 EQ 1
			DB	'/V40'			; could be a V40
					ENDIF
			DB	0
POST_LPT		DB	'LPT',  0
POST_COM		DB	'COM',  0
POST_FDD		DB	'FDD',  0
POST_HDD		DB	'HDD',  0
POST_LSEP		DB	POST_L, 0
POST_RSEP		DB	POST_R, 0

;----------------------------------------------------------------------------;
; NMI strings - these must be contiguous
;
NMI_ERR_IO		DB	'IO'				; NMI I/O Error string
NMI_ERR_PAR		DB	' PARITY', 0		; NMI Parity Error

POST_STRINGS ENDP

STRINGS ENDP

;============================================================================;
;
;		        * * *   P R O C s  &  I N T s  * * *
;
;============================================================================;

;----------------------------------------------------------------------------;
; Scan, checksum and call BIOS ROM init procedures
;----------------------------------------------------------------------------;
; Input:
;	AX = starting segment
;	DI = ending segment
; Output:
;	AX, DI = ending segment
;	DF = 0
;
; Clobbers: AX, BX, SI (anything else the ROM might, except for DS, ES and BP)
; Size: 67 bytes
;----------------------------------------------------------------------------;
BIOS_ROM_SCAN PROC
	PUSHX	BP, DS, ES				; call preserve these registers
CHECK_ROM:
	MOV	DS, AX 				; DS = starting segment
	XCHG	AX, BX				; BX = current DS segment
	MOV	AX, KBP < 2 >			; next 2K segment boundary length
	PUSH	AX					; save for use if no ROM found
	XOR	SI, SI 				; ROM offset to 0
	LODSW 					; AX = first word (must be 0AA55H)
	CMP	AX, MAGIC_WORD			; is it an extension ROM?
	JNE	NEXT_ROM 				; if not, check next 2K block
FOUND_ROM:
	CBW						; AH = 0
	LODSB						; AX = ROM size in 512B blocks
	CMP	AL, 1					; is size "reasonable"?
	JS	NEXT_ROM				; if not 1-128, skip it
	CALL	ROM_CHECKSUM 			; checksum ROM at DS:0, ZF if ok
			IF POST_OPT_ROM
	CALL	ROM_SCAN_POST			; show ROM offset, size and errors
			ENDIF
	JNZ	NEXT_ROM				; if NZ, checksum failed, skip it
	POP	BP					; discard previous boundary size
			IF ROM_SCAN_ALIGN EQ 1
	ADD	AL, KRB < 2 > - 1			; align next ROM segment to
	AND	AL, NOT KRB < 2 > - 1		;  2K boundary
			ENDIF
			IF CPU_TYPE	EQ CPU_V20
	SHL	AX, RB_P				; V20: 512 byte blocks to paragraph
			ELSE
	MOV	CL, RB_P				; 8088: 512 byte blocks to paragraph
	SHL	AX, CL
			ENDIF
	PUSH	AX					; replace next boundary with ROM size

;----------------------------------------------------------------------------;
; Call Option ROM's BIOS init routine
;
; Note: ROM init's can clobber any or all registers so important to save
; any that are used here between calls.
;
	IN	AL, INT_IMR 			; get current OCW1/IMR register
	PUSH	AX					; save IMR
	PUSH	DI					; save ROM scan ending segment
	PUSH	DS					; ROM init segment
	PUSH	SI					; ROM init offset (always 03H)
	MOV	BP, SP				; SS:BP = FAR pointer to ROM init
	CALL	DWORD PTR [BP]			; FAR CALL to option ROM init
	CLI						; ensure interrupts are still disabled
	POP	BX					; rebalance stack
	POP	BX					; restore current DS segment
	POP	DI					; restore ROM scan ending segment
	POP	AX					; restore IMR
	OUT	INT_IMR, AL				; reset IMR
	CLD						; ensure direction flag forward
NEXT_ROM:
	POP	AX					; restore next boundary size
	ADD	AX, BX				; next boundary
	CMP	AX, DI 				; end of extension ROM regions?
	JB	CHECK_ROM 				; if not, check next
ROM_SCAN_DONE:
	POPX	ES, DS, BP				; restore regs
	RET
BIOS_ROM_SCAN ENDP

;----------------------------------------------------------------------------;
; Perform 8 bit Checksum on a ROM at DS:0000
;----------------------------------------------------------------------------;
; Input:
;	DS = segment for ROM
;	AX = ROM size in 512 blocks
; Output:
;	ZF if checksum is valid
;	AX = ROM size in 512 blocks
;	DX = 8 bit checksum remainder
;
; Size: 20 bytes
;----------------------------------------------------------------------------;
ROM_CHECKSUM PROC
			ASSUME DS:NOTHING
	PUSH	AX				; save ROM size
	PUSH	CX
	PUSH	SI
	CWD					; DL = 0 (running checksum)
	MOV	SI, DX			; start at offset 0
	XCHG	AL, AH			; convert 512 byte blocks to 16 bit words
	XCHG	AX, CX			; CX = size in 2 byte WORDs
CHECKSUM_LOOP:
	LODSW					; next two bytes into AL and AH
	ADD	DL, AL			; add both to sum
	ADD	DL, AH			; ZF if sum is 0
	LOOP	CHECKSUM_LOOP		; loop through entire ROM
	POP	SI
	POP	CX
	POP	AX
	RET
ROM_CHECKSUM ENDP

;----------------------------------------------------------------------------;
; DETECT_MEMORY - Detect, test and clear RAM
;----------------------------------------------------------------------------;
; Attempt to determine how much RAM is installed using MEM_ADDR_TEST for 
; more reliable memory detection.
;
; Output: Memory count to console
; Clobbers: Everything except DS
;
; NOTE: Testing first two bytes of each block is problematic:
; http://minuszerodegrees.net/5160/problems/5160_known_problems_issues.htm
; http://minuszerodegrees.net/5160/problems/5160_ram_size_flaw.htm
;----------------------------------------------------------------------------;
DETECT_MEMORY PROC
			ASSUME DS:_BDA, ES:NOTHING
	PUSH	DS
	MOV	AX, SEG _BDA
	MOV	DS, AX

;----------------------------------------------------------------------------;
; 5150 or MAX_RAM_AUTO: get MAX RAM from MEM_SZ_PC
;
			IF ARCH_TYPE EQ ARCH_5150 OR MAX_RAM_AUTO EQ 1
	MOV	AX, MEM_SZ_PC			; SW2 RAM size in KB
				IF CPU_TYPE	EQ CPU_V20
	SHR	AX, 4					; V20: Number of 16KB RAM blocks
				ELSE
	MOV	CL, 4					; 8088: Number of 16KB RAM blocks
	SHR	AX, CL
				ENDIF
	XCHG	AX, CX				; CX = 16KB RAM blocks
	DEC	CX					;  after first 16K block
			ELSE
				IF ARCH_TYPE EQ ARCH_UM82
;----------------------------------------------------------------------------;
; UM82C088: get RAM status register
;
	CALL	UM82_MEM_SIZE			; CX = 16KB RAM blocks - 1

				ELSE
;----------------------------------------------------------------------------;
; Otherwise, use default for MAX_RAM and detect
;
	MOV	CX, MAX_RAM / 16 - 1		; Max number of 16KB RAM blocks
							; after the first 16K block
							; (ex: 640K / 16K - 1 = 39)
				ENDIF
			ENDIF

;----------------------------------------------------------------------------;
; Set up Nest/D-11 for UMA bank switching
;
			IF ARCH_TYPE EQ ARCH_TD3300 AND ARCH_SUB_TYPE EQ ARCH_NEST
			IF TD_UPMEM EQ 1
	IN	AL, N3_CTRL				; get current register
	PUSH	AX					; save register
	OR	AL, MASK D11UM			; enable upper memory
	OUT	N3_CTRL, AL
			ENDIF
			ENDIF

;----------------------------------------------------------------------------;
; Detect RAM size in 16K blocks
;
	MOV	DX, KBP < 16 >			; Start at second 16KB block para
	MOV	ES, DX				; ES = seg 0400H
BLOCK_LOOP:
	CALL	MEM_ADDR_TEST			; address test on 16KB RAM block at ES
	JNZ	BLOCK_LOOP_DONE			; exit loop if test failed
	ADD	DH, HIGH KBP < 16 >		; add 400h paras (16 KB)
	MOV	ES, DX
	LOOP	BLOCK_LOOP				; loop until MAX_RAM
BLOCK_LOOP_DONE:

;----------------------------------------------------------------------------;
; Test and clear RAM, show memory count
;
; Input:
;	ES/DX = highest memory segment detected
;
			IF ARCH_TYPE EQ ARCH_FE2010
	CALL	FE2010_SETUP_MEM			; set up FE2010 configuration
			ENDIF

			IF CPU_TYPE	EQ CPU_V20
	SHR	DX, 6					; V20: shift right 6 times to get K
			ELSE
	MOV	CL, 6					; 8088: shift right 6 times to get K
	SHR	DX, CL
			ENDIF
	MOV	MEM_SZ_KB, DX 			; save to BDA
	MOV	DX, ES				; DX = highest RAM segment detected

;----------------------------------------------------------------------------;
; Display RAM row
;
	POST_COL_1	POST_MEMORY, POST_CLR_VAL1 ; display RAM column, SI returned
							;  as POST_KB_OK (next string)
	CALL	OUT_SZ				; display '000 KB OK'
	POST_COL_END				; end post column
	XOR	BX, BX				; BX = 0, memory test counter
	MOV	ES, BX				; start at segment 0000
			IF ARCH_TYPE EQ ARCH_TD3300 AND ARCH_SUB_TYPE EQ ARCH_NEST
			IF TD_UPMEM EQ 1
	MOV	SI, 0AH				; start UMA test at bank 0AH
			ENDIF
			ENDIF
ZERO_ALL_RAM:
	XOR	AX, AX				; zero AX
	ADD	BX, 16				; increment memory count value
	CMP	BX, 100				; CF if two digit number
	ADC	AL, POST_COL_VT			; space inner column for 2 or 3 digits
			IF RAM_DIGITS GT 3
	CMP	BX, 1000				; CF if three digit number
	ADC	AL, 0					; space inner column for 3 or 4 digits
			ENDIF
	CALL	MOVE_COL				; move to start of inner column
	PUSH	BX					; save RAM size
	XCHG	AX, BX				; move RAM size to AX for display
	CALL	OUT_DECU				; display AX as decimal
	POP	BX					; restore RAM size
	MOV	AX, ES				; AX = last segment tested
	ADD	AX, KBP < 16 >			; move to next 16K segment/block
	CMP	AX, DX				; is last segment of RAM?
	JNB	DONE_ZERO_ALL_RAM			; exit if end
ZERO_ALL_RAM_1:
	MOV	ES, AX				; ES = last segment tested

			IF RAM_TEST_LONG EQ 1
	JWB	ZERO_ALL_START			; skip long tests on warm boot

;----------------------------------------------------------------------------;
; Perform memory checks on this block
;
TEST_MEM_LONG:
	CALL	NMI_RESET				; clear NMI/parity flags
	CALL	MEM_TEST				; read/write test on 16KB RAM block at ES
	JNZ	DETECT_MEMORY_ERR

			IF RAM_PARITY EQ 1
	XCHG	AX, DX				; save AX
	IN	AL, PPI_C				; read PPI Port C
	AND	AL, MASK PCPE OR MASK PCIE	; was there parity or NMI error?
	XCHG	AX, DX				; DL = parity error flag(s)
	JNZ	DETECT_MEMORY_ERR			; jump if parity error
			ENDIF				; END RAM_PARITY EQ 1
			ENDIF				; END RAM_TEST_LONG EQ 1

;----------------------------------------------------------------------------;
; Write 0's to all memory in this block
;
ZERO_ALL_START:
	XOR	AX, AX 				; write zeros
	MOV	CX, KBW < 16 >			; loop 16KB in WORDs
	MOV	DI, AX				; DI = beginning of segment
	REP	STOSW 				; write zero to next 16KB
	JMP	SHORT ZERO_ALL_RAM
DONE_ZERO_ALL_RAM:

			IF ARCH_TYPE EQ ARCH_TD3300
			IF TD_UPMEM EQ 1
;----------------------------------------------------------------------------;
; TD3300A: Check and clear upper memory bank
;----------------------------------------------------------------------------;
	JMP	TD3300_MEM_CLEAR			; handle bank clearing
TD_MEM_CLEAR_DONE:
			IF ARCH_SUB_TYPE EQ ARCH_NEST
;----------------------------------------------------------------------------;
; Restore N3/D-11 bank register
;
	POP	AX					; get saved register
	OUT	N3_CTRL, AL				; reset
			ENDIF				; ARCH_SUB_TYPE EQ ARCH_NEST
			ENDIF				; TD_UPMEM EQ 1
			ENDIF				; ARCH_TYPE EQ ARCH_TD3300

;----------------------------------------------------------------------------;
; Done with DETECT_MEMORY
;
	POP	DS
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
;----------------------------------------------------------------------------;
; Input:
; 	DL = 0 if no parity error, bit 7 or 6 set if error
;
DETECT_MEMORY_ERR:
			IF ARCH_TYPE EQ ARCH_TD3300
	PUSH	SI					; preserve SI for TD3300_MEM_CLEAR
			ENDIF
	POST_FLAG_SET  PMEM			; set POST Memory error flag
	CALL	CRLF					; start on new line
	POST_COL_1	POST_ERR_ERR, RED
	DEC	DI					; move back to last address
	DEC	DI
	XOR	AX, ES:[DI]				; determine incorrect bit(s)
	XCHG	AX, DI				; DI = bit pattern, AX = err offset
	MOV	BX, ES				; segment of error
	CALL	DWORD_HEX				; write address
	TEST	DL, DL				; was there a parity error?
	JZ	DETECT_MEMORY_ERR_2		; jump if not
	PRINT_SZ  NMI_ERR_PAR			; print 'PARITY'
	JMP	SHORT DETECT_MEMORY_ERR_DONE
DETECT_MEMORY_ERR_2:
	XCHG	AX, DI				; restore failed bit pattern
	CALL	SPACE
	CALL	WORD_HEX
DETECT_MEMORY_ERR_DONE:
	POST_COL_END
			IF ARCH_TYPE EQ ARCH_TD3300
	POP	SI
			ENDIF
	JMP	SHORT DONE_ZERO_ALL_RAM
DETECT_MEMORY ENDP

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
; Clobbers AL, DI
;
; Inspired by:
; http://www.ganssle.com/testingram.htm
; http://www.paul.de/tips/ramtest.htm
; https://www.memtest86.com/tech_memtest-algoritm.html
; Size: 38 bytes
;----------------------------------------------------------------------------;
MEM_ADDR_TEST PROC
	MOV	AL, 1					; pattern to rotate
	XOR	BX, BX				; base address
	MOV	DI, 2000H				; highest address in 16KB segment
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
; Output:
;	ZF and AX = 0 if pass, NZ if fail
;
; Clobbers: AX, CX, DI
;
; Size: 26 bytes
;----------------------------------------------------------------------------;
MEM_TEST PROC
	MOV	AX, RAM_TEST			; test pattern
	CALL	MEM_CHECK				; write and verify pattern
	JNZ	MEM_ADDR_ERR			; return if error
	MOV	AX, NOT RAM_TEST			; inverted test pattern

;----------------------------------------------------------------------------;
; Write and verify a 16KB block of Memory at ES:0000
;----------------------------------------------------------------------------;
; Input:
;	AX = pattern to write
; 	ES = segment for test
; Output:
;	ZF and AX = 0 if pass, NZ if fail
;
; Clobbers: AX, CX, DI
;----------------------------------------------------------------------------;	
MEM_CHECK PROC
	MOV	CX, KBW < 16 >			; loop 16KB in WORDs
	XOR	DI, DI 				; start at offset 0
	REP	STOSW 				; write test pattern
MEM_TEST_VERIFY:
	MOV	CH, HIGH KBW < 16 >		; restart loop 16KB in WORDs
	XOR	DI, DI 				; start at offset 0
	REPZ	SCASW 				; loop until CX = 0 OR WORD is not AX
	XCHG	AX, CX				; AX = 0 if success
	RET
MEM_CHECK ENDP
MEM_TEST ENDP

;----------------------------------------------------------------------------;
; Reset NMI enable flags
;----------------------------------------------------------------------------;
; Output:
;	AL = current PPI B flags
;
; Size: 11 bytes
;----------------------------------------------------------------------------;
NMI_RESET PROC
	IN	AL, PPI_B				; read current flags
	OR	AL, MASK PBIO OR MASK PBPC	; parity, I/O flags high (disable)
	OUT	PPI_B, AL				; write to PPI
	XOR	AL, MASK PBIO OR MASK PBPC	; flags low (enable)
	OUT	PPI_B, AL				; write to PPI
	RET
NMI_RESET ENDP

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
; - Calculate the total number of PIT ticks necessary (where 1,193,182 = 1s)
; - Latch the PIT and draw down the countdown total on each read.
; - Exit when countdown underflows.
;
; Note: Mode 3 (Square Wave) decements the readable counter by 2, so the
; effective frequency of the counter is actually 2,386,364 Hz.
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
	MOV	BX, 1193 * 2		; 1,193,182 / 1000 ms * 2 = 2,386 ticks/ms

;----------------------------------------------------------------------------;
; Delay using PIT counter DX:AX number of ticks
;----------------------------------------------------------------------------;
IO_DELAY_TICK PROC
	PUSH	CX
	PUSH	DX
	MUL	BX				; DX:AX = countdown of PIT ticks to wait
	XCHG	AX, BX			; DX:BX = countdown ticks
	CALL	IO_WAIT_LATCH		; AX = start read
IO_WAIT_MS_LOOP:
	MOV	CX, AX			; CX = last read
	CALL	IO_WAIT_LATCH		; AX = current counter reading
	SUB	CX, AX			; CX = # of ticks elapsed since last reading

		IF MUSHROOM_HACK EQ 1
;----------------------------------------------------------------------------;
; If the PIT has not changed, the counter may be stopped. Use an estimate
; value to simulate the countdown.
;
	JNE	PIT_CHANGED			; continue if PIT did change
		IF IS_TURBO
	SUB	CX, 75			; assume 75 ticks for a turbo PC
		ELSE
	SUB	CX, 100			; assume 100 ticks for standard
		ENDIF
PIT_CHANGED:
		ENDIF
	SUB	BX, CX			; subtract change in ticks from countdown
	SBB	DX, 0				; borrow out of high word (if necessary)
	JAE	IO_WAIT_MS_LOOP		; loop while countdown >= 0
	POP	DX
	POP	CX
	POP	BX
IO_WAIT_MS_DONE:
	RET

;----------------------------------------------------------------------------;
; Latch PIT 0 and read counter to AX
;----------------------------------------------------------------------------;
; Output: AX = current counter
; Time: 123 clock cycles (including CALL)
;----------------------------------------------------------------------------;
IO_WAIT_LATCH PROC
	MOV	AL, PIT_CW <0, 0>		; Counter 0, Latch (00b)
	PUSHF					; save current IF
	CLI					; disable interrupts
	OUT	PIT_CTRL, AL		; Write command to CTC
	IN	AL, PIT_CH0			; Read low byte of Counter 0 latch
	MOV	AH, AL			; Save it
	IN	AL, PIT_CH0			; Read high byte of Counter 0 latch
	POPF					; restore IF state
	XCHG	AL, AH			; convert endian
	RET
IO_WAIT_LATCH ENDP
IO_DELAY_TICK ENDP
IO_DELAY_MS ENDP
IO_WAIT_MS_125 ENDP

		IF UNSAFE_FLOPPY EQ 1
;----------------------------------------------------------------------------;
; Delay using PIT counter increments of UNSAFE_FLP_DIV ms for floppy drive
; head settling time.
;----------------------------------------------------------------------------;
IO_DELAY_MS_FDC PROC
	PUSH	BX
	MOV	BX, 1193 * 2 * UNSAFE_FLP_DIV
	JMP	SHORT IO_DELAY_TICK
IO_DELAY_MS_FDC ENDP
		ELSE
IO_DELAY_MS_FDC	EQU IO_DELAY_MS
		ENDIF

		IF CASSETTE EQ 1
;----------------------------------------------------------------------------;
; CAS_READ_WORD: read 16 bits, add to working CRC
;----------------------------------------------------------------------------;
; Output:
;	AX = word read (little endian)
;	CF if error
;----------------------------------------------------------------------------;
CAS_READ_WORD PROC
	CALL	CAS_READ_BYTE
	JC	CAS_READ_BYTE_RET

;----------------------------------------------------------------------------;
; CAS_READ_BYTE: read 8 bits, add to working CRC
;----------------------------------------------------------------------------;
; Output:
;	AL = byte read
;	CF if error
;
; Clobbers: AH, BL, DX
;----------------------------------------------------------------------------;
CAS_READ_BYTE PROC
	PUSH	CX				; save CX
	MOV	CX, 8				; loop 8 bits

;----------------------------------------------------------------------------;
; CAS_READ_BIT: read 1 bit (2 cycles)
;----------------------------------------------------------------------------;
CAS_READ_BIT PROC
CAS_READ_BIT_LOOP:
	CALL	CAS_READ_CYCLE		; DX = read low cycle length
	STC					; presume failure
	JZ	CAS_READ_BYTE_EXIT	; exit if unable to read
	PUSH	DX				; save low length
	CALL	CAS_READ_CYCLE		; DX = read high cycle length
	POP	AX				; AX = low length
	STC					; presume failure
	JZ	CAS_READ_BYTE_EXIT
	ADD	AX, DX			; AX = full cycle length

;----------------------------------------------------------------------------;
; Determine bit value based on full cycle duration with 33% tolerance.
;
; 1: 2t * 1193182 (Hz) / 1007 Hz = ~ 2368 ticks
; 0: 2t * 1193182 (Hz) / 2014 Hz = ~ 1184 ticks
; (Note: raw timer counter readings are doubled, so must be adjusted by 2x)
;
; BEEP_1K7 = 1184 ticks = ~1007 Hz
; BEEP_2K  = 592 ticks  = ~2014 Hz
;
; Use median of values to determine maximum length of a '1' bit cycle:
; 1184 + 592 -> 1776 / 2 = ~ 1344 Hz = ~ 33% tolerance
;
	MOV	DX, BEEP_1K7 + BEEP_2K	; DX = median cycle length
	CMP	DX, AX			; above or below median freq?
	CALL	CAS_CRC_ADD			; add bit to working CRC
	CMP	DX, AX			; above or below median freq?
	ADC	BL, BL			; add bit to result
	LOOP	CAS_READ_BIT_LOOP
	MOV	AL, BL			; AL = result
CAS_READ_BIT ENDP
	CLC					; no error
CAS_READ_BYTE_EXIT:
	POP	CX
CAS_READ_BYTE_RET:
	RET

CAS_READ_BYTE ENDP
CAS_READ_WORD ENDP
		ENDIF				; CASSETTE EQ 1
;
; 25 BYTES HERE / 22 BYTES HERE 5150
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
	MOV	DI, OFFSET IVT_1E			; INT 1E vector table address
	MOV	AX, OFFSET INT_1E 		; INT 1E DBT address
	STOSW
	MOV	AX, CS				; INT 1E DBT segment
	STOSW
INT_19_READ_MBR:
	XCHG	AX, CX				; AH = 0 (reset)
	INT	13H					; reset disk 0
	JC	INT_19_IPL_FAIL			; exit if error
	MOV	AX, DBW <2, 1>			; AH = 2 (read), AL = 1 sector
	MOV	BX, OFFSET IPL_TOP		; ES:BX = IPL boot sector offset
	MOV	CX, DBW <0, 1>			; CH = cyl 0, CL = sec 1
	MOV	DH, CH 				; DH = head 0, DL = drive #
	INT	13H					; read 1 sector into ES:BX
	JC	INT_19_IPL_FAIL			; exit if error
			IF MBR_CHECK EQ 1
	CMP	IPL_ID, MAGIC_WORD		; verify bootable MBR signature
	JNZ	INT_19_IPL_FAIL			; jump if MBR not bootable
			ENDIF
	JMP 	FAR PTR IPL_TOP 			; jump to IPL segment and boot!
INT_19_IPL_FAIL:
	IRET
		ASSUME DS:NOTHING, ES:NOTHING
INT_19 ENDP

		IF POST_HD_CHECK EQ 1
;----------------------------------------------------------------------------;
;  Get Hard Drive Parameters
;----------------------------------------------------------------------------;
;  Input:
;	DL = drive number
;  Output:
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
	JC	GET_DISK_PARAMS_ERR 	; if error, exit
	MOV	BX, CX 			; BX = last cylinder
	XCHG	BH, BL 			; swap bytes
	ROL	BH, 1 			; rotate high two bits into low bits
	ROL	BH, 1
	AND	BH, 11B			; BX = cylinder (10 bits)
	AND	CX, 00111111B		; CX = logical last index of sectors/track
	MOV	AL, DH
	INC	AX				; convert heads to 1 index (count)
	INC	BX				; convert cylinders to 1 index
	XOR	DH, DH			; clear high byte of DX, CF = 0
GET_DISK_PARAMS_ERR:
	RET
GET_DISK_PARAMS ENDP
		ENDIF

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
;	  AH = function number (bounds not checked)
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
	STI 					; enable interrupts
	PUSH	CX 				; call-preserve CX
	MOV	CX, 3 			; will use this 3 in multiple places
	CMP	DX, CX			; is port number valid?
	JA	INT_14_EXIT 		; exit if port is > 3
	PUSHX	DI, BX, DX, DS		; call-preserve registers
	MOV	DI, SEG _BDA 		; DS = BDA
	MOV	DS, DI
	MOV	DI, DX 			; DI = COM port index (0-3)
	MOV	BX, DI			; convert to word index
	CWD					; DX = 0
	ADD	DX, [BX][DI]		; DX = 3F8/2F8 base port address
	JZ	INT_14_DONE 		; is port index valid (detected)?
	CMP	AH, CL			; check function number (CL = 3)
	JA	INT_14_DONE			; > 3? Not valid
	JZ 	INT_14_3	 		; = 3 then status
	CMP	AH, 1				; check remaining functions
	JA	INT_14_2 			; = 2 then read
	JZ	INT_14_1 			; = 1 then write
						; = 0 fall through to init

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
;	AL = port params, AH = 0
;	CX = 3 (from earlier)
;----------------------------------------------------------------------------;

INT_14_0 PROC
;----------------------------------------------------------------------------;
; Set baud rate
;
	MOV	DI, DX 			; DX = 3F8/2F8 base port
	ADD	DX, CX			; DX = 3FB/2FB Line Control Register (LCR), CX = 3
	XCHG	AX, BX			; save port params to BL
	MOV	AL, MASK DLAB 		; set baud rate divisor (DLAB); 0 = RBR, THR or IER
	OUT	DX, AL 			; write to 3FB/2FB (LCR)
	SHL	BX, CL 			; BH = baud rate, CL = 3
	SHR	BL, CL 			; BL = flags
	MOV	AX, 417H 			; divisor for 110 baud
	MOV	CL, BH 			; CL = shift counter or 0 for 110 baud (CH = 0)
	JCXZ	INT_14_0_SET_BAUD		; Jump if 110 baud
	MOV	AX, 600H 			; AX = divisor base (see above formula)
	SHR	AX, CL			; divisor = 600H >> CL
INT_14_0_SET_BAUD:
	XCHG	DX, DI 			; DX = 3F8/2F8, DI = 3FB/2FB (4)
						; AL = Divisor LSB, AH = Divisor MSB (4)
	OUT	DX, AX			; write LSB, then MSB to ports 3F8/3F9
;----------------------------------------------------------------------------;
; Set parity, stop and word bits
; 
INT_14_0_SET_PSW:
	XCHG	AX, BX 			; AL = parity, stop and word bits (4)
	XCHG	DX, DI 			; DX = 3FB/2FB, DI = 3F8/2F8 (4)
	OUT	DX, AL			; set LCR parity, stop and word bits
	XCHG	DX, DI 			; DX = 3F8/2F8, DI = 3FB/2FB (4)
;----------------------------------------------------------------------------;
; Disable IER
;
	XOR	AX, AX 			; AL = 0 (3)
	INC	DX 				; DX = 3F9/2F9 (3)
	OUT	DX, AL			; DX = 3F9 - Interrupt Enable Register (IER) disabled
	DEC	DX 				; DX = 3F8 (3)
						; fall through to get status

;----------------------------------------------------------------------------;
; INT 14,3  Get Serial port status
;----------------------------------------------------------------------------;
; Input:
; 	DX = base port address
; Output:
;	AH = port status
;	AL = modem status
;----------------------------------------------------------------------------;
INT_14_3 PROC
	ADD	DX, COM1_LSR-COM1_DATA	; DX = 3FD/2FD LSR - Line Status Register
	PUSH	BX				; delay for I/O
	IN	AL, DX 			; get line/port status 
	XCHG	AH, AL 			; save to AH
	INC	DX 				; DX = 3FE/2FE MSR - Modem Status Register
	POP	BX 				; delay for I/O
	IN	AL, DX 			; get modem status 
INT_14_3 ENDP

INT_14_DONE PROC
	POPX	DS, DX, BX, DI		; restore all registers

INT_14_EXIT:
	POP	CX
	IRET
INT_14_DONE ENDP

INT_14_0 ENDP

;----------------------------------------------------------------------------;
; INT 14, 1 - Send/write character in AL
;----------------------------------------------------------------------------;
; Input:
; 	DX = base port address
;	BL = port timeout
;----------------------------------------------------------------------------;
INT_14_1 PROC
	PUSH	DX 					; save base port
	PUSH	AX
	ADD	DX, COM1_MCR-COM1_DATA		; DX = 3FC/2FC - Modem Control Register
	MOV	AL, MASK RTS OR MASK DTR	; activate DTR & RTS
	OUT	DX, AL				; set DTR or RTS
	INC	DX
	INC	DX 					; DX = 3FE - Modem Status Register
	MOV	BX, DBW <MASK THRE OR MASK LBI, MASK MDSR> ; BH = line (THRE)
							;  BL = modem (DSR/CTS)
	CALL	INT_14_POLL 			; poll both registers, AH = status
	POP	BX
	MOV	AL, BL 				; AL = output char
	POP	DX 					; restore base port
	JNZ	INT_14_RW_ERR			; Jump if port timeout
	OUT	DX, AL
	JMP	SHORT INT_14_DONE
INT_14_RW_ERR:
	OR	AH, 10000000B			; set error bit
	JMP	SHORT INT_14_DONE
INT_14_1 ENDP

;----------------------------------------------------------------------------;
; INT 14, 2 - Receive/read character in AL
;----------------------------------------------------------------------------;
; Input:
;	DX = base port address
;	BL = port timeout
; Output:
;	AH = port status
;	AL = character read
;	NZ = timeout or failure occurred
;
; Clobbers: BX
;----------------------------------------------------------------------------;
INT_14_2 PROC
	PUSH	DX 					; save base port
	ADD	DX, COM1_MCR-COM1_DATA		; DX = 3FC/2FC - Modem Control Register
	MOV	AL, MASK DTR			; activate DTR
	OUT	DX, AL				; set DTR
	INC	DX
	INC	DX 					; DX = 3FE/2FE - Modem Status Register
	MOV	BX, DBW <MASK MDSR, MASK LDR>	; BH = modem (DSR), BL = line (data ready)
	CALL	INT_14_POLL 			; poll both registers, AH = status
	POP	DX 					; restore base port
	AND	AH, MASK LBI OR MASK LFE OR MASK LPE OR MASK LOE ; include only 
							;  error bits in port status
	IN	AL, DX				; read char from buffer
	JMP	SHORT INT_14_DONE
INT_14_2 ENDP

;----------------------------------------------------------------------------;
; INT 14 - Poll line then modem status registers
;----------------------------------------------------------------------------;
; Input:
;	DI = port index (0 based byte)
; 	DX = 3FE Modem Status Register
;	BL = line status expected masked
;	BH = modem status expected masked
; Output:
;	AH = port status
;	DX = 3FD Line Status Register
;	NZ = timeout or failure occurred
;
; Clobbers: AX, CX
;----------------------------------------------------------------------------;
INT_14_POLL PROC
	CALL	INT_14_POLL_PORT 		; first poll modem status
	JNZ	INT_14_POLL_RET  		; jump if ZF = 0, timeout or failure occurred
	XCHG	BH, BL 			; BH = line status
	DEC	DX				; DX = 3FD Line Status Register (LSR)

;----------------------------------------------------------------------------;
; INT 14 - Poll status register in DX
;----------------------------------------------------------------------------;
INT_14_POLL_PORT PROC
	PUSH	SI 				; call-preserve SI
	XOR	CX, CX			; reset poll loop counter
	MOV	AL, COM_TIME_B[DI]	; AL = port timeout (< 127)
	CBW					; zero extend AX
	XCHG	AX, SI 			; SI = port timeout
INT_14_POLL_LOOP:
	IN	AL, DX 			; check port status
	MOV	AH, AL 			; save to AH
	XOR	AL, BH 			; mask result bits
	TEST	AL, BH 			; did it match expected result?
	JZ	INT_14_POLL_DONE
	LOOP	INT_14_POLL_LOOP		; poll port 65,535 * timeout times
	DEC	SI 				;
	JNZ	INT_14_POLL_LOOP		; Jump if timeout not expired
INT_14_POLL_DONE:
	POP	SI
INT_14_POLL_RET:
	RET
INT_14_POLL_PORT ENDP
INT_14_POLL ENDP

INT_14 ENDP

;----------------------------------------------------------------------------;
; I/O port register test
;----------------------------------------------------------------------------;
; Do a Walking Bit/March test on I/O port registers.
;
; Input:
;	DX = starting port
;	AH = number of sequential ports to test
; Output:
;	ZF and CX = 0 if success
;	NZ if failed
;
; Adapted from:
; https://barrgroup.com/embedded-systems/how-to/memory-test-suite-c
; https://www.edaboard.com/threads/walking-1-0-test-for-memory-bist.241278/
;
; Size: 47 bytes
; Clobbers AX, BX, CX, DX, DI
;----------------------------------------------------------------------------;
PORT_TEST PROC
	MOV	BH, 1				; start with low order bit
	XOR	CX, CX			; clear counter
	MOV	DI, DX			; save starting port

;----------------------------------------------------------------------------;
; Write a single 1 bit to a different position in each register
;
WB_WRITE_1:
	MOV	CL, AH			; register counter
	MOV	DX, DI 			; start at first register
	MOV	AL, BH			; AL = starting bit to write
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
	MOV	CL, AH			; register counter
	MOV	DX, DI 			; start at first register
	MOV	BL, BH			; BL = starting bit to compare
WB_READ_LOOP:
	IN	AL, DX			; read low byte
	CMP	AL, BL			; compare to correct bit
	JNZ	PORT_TEST_DONE		; jump if not okay
WB_LOW_CHECK_OK:
	IN	AL, DX			; read high byte
	CMP	AL, BL			; compare to correct bit
	JNZ	PORT_TEST_DONE		; jump if not okay
	INC	DX				; next register/port
	ROL	BL, 1				; rotate for next register/bit
	LOOP	WB_READ_LOOP		; loop all eight registers
	SHL	BH, 1				; rotate to next starting bit
	JNZ	WB_WRITE_1			; loop until BH = 0
PORT_TEST_DONE:
	RET
PORT_TEST ENDP
			IF POST_VIDEO_TYPE EQ 1
;----------------------------------------------------------------------------;
; POST Video Adapter Type Strings
; 17 bytes
;
POST_VGA		DB	'VGA', 0
POST_EGA		DB	'EGA', 0
POST_CGA		DB	'CGA', 0
POST_MDA		DB	'Mono', 0
			ENDIF

;----------------------------------------------------------------------------;
; POST Initial INT 10H Video Mode to BIOS video equipment type
;
VID_MODE_TBL	DB	1, 3, 7	; Color 40x25, Color 80x25, Mono 80x25

;
; 0 BYTES HERE
;
BYTES_HERE	INT_16

;----------------------------------------------------------------------------;
; INT 16 - Keyboard BIOS Services
;----------------------------------------------------------------------------;
;	INT 16,0	Wait for keystroke and read
;	INT 16,1	Get keystroke status
;	INT 16,2	Get shift status
; Enhanced:
;	INT 16,5	Keyboard buffer write
;	INT 16,10	Wait for keystroke and read
;	INT 16,11	Get keystroke status
;	INT 16,12	Get shift status
;----------------------------------------------------------------------------;
		ORG 0E82EH
INT_16 PROC
		ASSUME DS:_BDA
	STI					; necessary?
	CLD
	PUSH	DS
	PUSH	SI
	MOV	SI, SEG _BDA
	MOV	DS, SI 			; DS = BDA segment
	CMP	AH, 2
	JE	KB_SHIFT_STATUS 		; AH = 2 - Get Shift Status
	JA	INT_16_DONE			; AH > 2 - Not valid, exit
	JNP	KB_WAIT_READ_1		; AH = 0 - Wait for keystroke and read
						; AH = 1 - Get keystroke (fall through)

;----------------------------------------------------------------------------;
; AH = 1 - Get keystroke status
;----------------------------------------------------------------------------;
; Check if a key press is in buffer and return. Does not wait or remove.
; Output:
;	ZF = 0 if a key pressed (even Ctrl-Break)
;	AH = scan code
;	AL = ASCII character or zero if special function key
;----------------------------------------------------------------------------;
;	KB_BUF_HD (1Ah) = "head" next character stored in keyboard buffer
;	KB_BUF_TL (1Ch) = "tail" next spot available in keyboard buffer
;----------------------------------------------------------------------------;
KB_KEY_STATUS PROC
	MOV	SI, OFFSET KB_BUF_HD 	; SI = head ptr
	CLI 					; disable interrupts (already off)
	LODSW 				; AX = head, SI = tail ptr
	CMP	AX, [SI]	 		; head == tail?
	JNE	KB_BUF_HAS_KEY 		; if not, buffer has a key
KB_KEY_STATUS_DONE:
	STI					; re-enable interrupts
	POP	SI
	POP	DS
	IRET_F				; IRET with current flags
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
		IF KB_HLT_WAIT EQ 1
	HLT					; wait for keystroke interrupt
		ELSE
	NOP					; wait for any interrupt
		ENDIF
KB_WAIT_READ_1:
	MOV	SI, OFFSET KB_BUF_HD 	; SI = head ptr
	CLI 					; disable interrupts again
	LODSW 				; AX = head, SI = tail ptr
	CMP	AX, [SI] 			; head == tail?
	JE	KB_WAIT_READ 		; if so, buffer is empty
	XCHG	AX, SI 			; SI = tail
	LODSW 				; AX = buffer[tail], SI = next
	CMP	SI, KB_BUF_END_B		; is next >= end of buffer?
	JB	KB_GET_READ 		; if not, get tail value
	MOV	SI, OFFSET KB_BUF 	; otherwise, wrap next to buffer top
KB_GET_READ:
	MOV	KB_BUF_HD, SI 		; head ptr = next
INT_16_DONE:
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

BEEP_PROC PROC

;----------------------------------------------------------------------------;
; Repeats LONG_BEEPs then SHORT_BEEPs indefinetly
;----------------------------------------------------------------------------;
; Input:
;	BL low nibble = long beeps
;	BL high nibble = short beeps
;
; Note: must use LOOP for beep since BEEP could occur if PIT is not working
;  (then how does the speaker work?)
; Note 2: cannot use stack since HALT_BEEP could occur before stack
;
; Size: 60 bytes
;----------------------------------------------------------------------------;
HALT_BEEP PROC
	MOV	DX, CS 				; SS to CS
	MOV	SS, DX				; for CALL_NS
	XCHG	AX, BX				; beep pattern to AL
	POST_CODE					; optionally display beep code on POST card
	AAM_I	10H					; split nibbles
	XCHG	AX, BP				; BP(H) = short beeps, BP(L) = long beeps
HALT_BEEP_START:
	IO_DELAY_TURBO				; pause between sequences, CX = 0
	MOV	DX, BP 				; restore original beep pattern
	MOV	SI, BEEP_ERR_LOW			; low C5
HALT_BEEP_NEXT:
	MOV	DI, CX				; set beep duration for this loop
HALT_BEEP_REP:
	MOV	AX, SI				; restore beep tone
	CALL_NS  BEEP_ON_P, 1			; turn on speaker/beep, BL = old PPI state
	MOV	CX, DI				; reset counter
	IO_DELAY_TURBO				; delay for beep (longer if turbo)
	XCHG	AX, BX				; AL = old PPI state (speaker off)
	OUT	PPI_B, AL				; write back to PPI port B
	SUB	CX, DI				; set for remainder of counter
	IO_DELAY_TURBO				; delay for silence (longer if turbo)
	DEC	DL					; dec beep repeat count
	JNZ	HALT_BEEP_REP			; jump if more of this length
	XCHG	DL, DH				; swap beep counts
	TEST	DX, DX				; both cycles done?
	JZ	HALT_BEEP_START			; if so, restart beep pattern
	MOV	CH, 100H * 1/3			; else, short beep on 33%
	MOV	SI, BEEP_ERR_HIGH			; high F5
	JMP	HALT_BEEP_NEXT			; start short cycle
HALT_BEEP ENDP

;----------------------------------------------------------------------------;
; Make a beepin' beep
;----------------------------------------------------------------------------;
; Play a (correctly pitched) A6 for 250ms
; Clobbers: BX
;----------------------------------------------------------------------------;
BEEP PROC
	PUSH	AX
	BEEP_ON
	MOV	AL, 2				; 1/4 second pause
	CALL	IO_WAIT_MS_125
	BEEP_OFF
	POP	AX
	RET
BEEP ENDP

;----------------------------------------------------------------------------;
; Two very short beeps if ZF, one short if NZ
;----------------------------------------------------------------------------;
MEEPMEEP_Z PROC
	JNZ	MEEP				; if ZF=0, skip first meep

;----------------------------------------------------------------------------;
; Two very short beeps
; Size: 27 bytes
; Output: CX = 0
;----------------------------------------------------------------------------;
			IF IS_TURBO
MEEP_DELAY	EQU	40H
			ELSE
MEEP_DELAY	EQU	20H
			ENDIF
MEEPMEEP PROC
	CALL MEEP				; first meep

;----------------------------------------------------------------------------;
; One very short beep
; Clobbers: BX, CX
;----------------------------------------------------------------------------;
MEEP PROC
	PUSH	AX
	BEEP_ON
	MOV	CH, MEEP_DELAY
	IO_DELAY				; delay while meeping
	BEEP_OFF
	MOV	CH, MEEP_DELAY
	IO_DELAY				; delay between beeps
	POP	AX
	RET
MEEP ENDP
MEEPMEEP ENDP
MEEPMEEP_Z ENDP

;----------------------------------------------------------------------------;
; Turn on speaker at given tone
;----------------------------------------------------------------------------;
; Input:
; 	AX = TONE
; Output:
;	BL = previous PPI state
;
; http://www.cs.binghamton.edu/~reckert/220/8254_timer.html
;
; Clobbers AX, BX
; Cannot use stack since this could be called before it is working.
;----------------------------------------------------------------------------;
BEEP_ON_P PROC
	XCHG	AX, BX				; save tone to BX
	MOV	AL, PIT_CW <2, 11B, 3>		; Select Timer 2, LE, Mode 3 (square)
	OUT	PIT_CTRL, AL			; Send to PIT control word (43H)
	XCHG	AX, BX				; restore tone
	OUT	PIT_CH2, AL				; send low byte to timer
	MOV	AL, AH 				; select high byte
	OUT	PIT_CH2, AL				; send high byte to timer
	IN	AL, PPI_B				; read current PPI port B status
	MOV	BL, AL				; save original PPI state
	OR	BL, MASK PBSP OR MASK PBST	; enable speaker and timer gates

;----------------------------------------------------------------------------;
; Write to PPI (turn speaker on/off)
;----------------------------------------------------------------------------;
; Input: BL = new PPI state
;
BEEP_OFF_P PROC
	XCHG	AX, BX				; AL = new PPI state
	OUT	PPI_B, AL				; write back to port B
	RET
BEEP_OFF_P ENDP
BEEP_ON_P ENDP

BEEP_PROC ENDP

;----------------------------------------------------------------------------;
; Additional POST messages
;----------------------------------------------------------------------------;
				IF POST_WARM_COLD EQ 1
POST_BOOT		DB	'Boot', 0
POST_WARM		DB	'WARM', 0
POST_COLD		DB	'COLD', 0
				ENDIF

;----------------------------------------------------------------------------;
; Display all POST messages
;----------------------------------------------------------------------------;
; See PFLAGS
; Output: BP (high byte) = 0
; Clobbers: AX, CX, SI
; Size: 63 bytes
;----------------------------------------------------------------------------;
POST_ERR_MSG PROC

;----------------------------------------------------------------------------;
; POST Error Strings
;
POST_ERR		DB	CR, LF, 'POST '	; POST Error
POST_ERR_ERR	DB	'Error ', 0		; Error
POST_ERR_PKI	DB	'KB',   0		; Reset returned non-success "301"
POST_ERR_PKEY	DB	'Key',  0		; Reset did not clear KBC
POST_ERR_PFDC	DB	'FDC',  0		; General FD init failure
POST_ERR_PDMA	DB	'DMA',  0		; DMA TC0 error

;----------------------------------------------------------------------------;
; POST String Vectors - indexed by PFLAGS
;
POST_ERRORS LABEL WORD
	DW	OFFSET POST_ERR_PKI		; PKI  : Keyboard Interrupt Error
	DW	OFFSET POST_ERR_PKEY		; PKEY : Keyboard Key Stuck
	DW	OFFSET POST_ERR_PFDC		; PFDC : FDC Init Failure
	DW	OFFSET POST_FDD			; PFSK : FDC Seek Test Failure
	DW	OFFSET POST_ERR_PDMA		; PDMA : DMA TC0 Error
	DW	OFFSET POST_MEMORY		; PMEM : RAM Error
L_POST_ERRORS	EQU	($-POST_ERRORS)/SIZE POST_ERRORS

POST_ERROR_MSG PROC
	MOV	CX, L_POST_ERRORS+1		; # of available POST error messages
	MOV	SI, OFFSET POST_ERRORS-2	; SI = string table pointer
							;  add one LOOP for WARM BOOT flag
POST_ERROR_MSG_LOOP:
	LODS	WORD PTR CS:[SI]			; AX = next message offset
	SHL	BP, 1					; CF = POST error flag
	JNC	POST_ERROR_MSG_NEXT		; no flag?
	PUSHF						; save BP ZF
	XCHG	AX, SI				; SI = error string
	PRINTLN_SZ  SI				; write string with CRLF
	XCHG	AX, SI				; SI = string table pointer
	POPF
POST_ERROR_MSG_NEXT:
	LOOPNZ  POST_ERROR_MSG_LOOP		; loop until end of strings or flags
POST_ERROR_MSG_EXIT:
	RET
POST_ERROR_MSG ENDP

POST_ERR_MSG ENDP

;----------------------------------------------------------------------------;
; Additional INT 9h - Keyboard Code
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
; INT 9 - Test keyboard during POST
; Size: 27 bytes
;----------------------------------------------------------------------------;
INT_09_POST PROC
	PUSH	AX
	POST_FLAG_CLR PKI				; clear POST test int flag
	IN	AL, PPI_A				; read keyboard scan from PPI
			IF OEM_KB_EXT EQ 1
;----------------------------------------------------------------------------;
; XT 101 keyboards can return 0EAh on initial power on reset
;
	AND	AL, NOT 0EAH XOR 0AAH		; transform EAh -> AAh
			ENDIF
	CMP	AL, 0AAH
	JNE	INT_09_POST_DONE			; jump if not expected AAh
	POST_FLAG_SET PKI				; set POST keyboard test pass flag
INT_09_POST_DONE:
	IN	AL, PPI_B				; read keyboard status
	OR	AL, MASK PBKB OR MASK PBKC	; set clear keyboard and enable clock
	OUT	PPI_B, AL				; write to PPI Control Port B
	MOV	AL, EOI				; Send End of Interrupt
	OUT	INT_P0, AL
	POP	AX
	IRET
INT_09_POST ENDP

;----------------------------------------------------------------------------;
; Clear keyboard circular buffer
;----------------------------------------------------------------------------;
; Clear/init circular buffer at KB_BUF
; Clobbers AX, DI
;
; Size: 16 bytes
;----------------------------------------------------------------------------;
KB_BUF_CLEAR PROC
		ASSUME ES:_BDA_ABS
	PUSH	ES 					; save ES
	XOR	AX, AX
	MOV	ES, AX
	MOV	AX, ES:KB_BUF_ST_ABS 		; AX = original start of buffer
	MOV	DI, OFFSET KB_BUF_HD_ABS	; DI = buffer head
	STOSW 					; write to head pointer
	STOSW 					; write to tail pointer
	POP	ES
	RET
		ASSUME ES:NOTHING
KB_BUF_CLEAR ENDP

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

;
; 1 BYTE HERE
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
	MOV	AL, EOI 					; End of Interrupt OCW
	OUT	INT_P0, AL					; write EOI to port 0
	STI							; enable interrupts
	CLD							; string functions increment
			IF CPU_TYPE EQ CPU_V20
	PUSHA							; save working registers
			ELSE
	PUSHX	BX, CX, DX, DI, SI			; save working registers
			ENDIF
	PUSHX	DS, ES					; save segment registers
	MOV	CX, SEG _BDA 				; CX = BIOS Data Area, CH = 0
	MOV	AL, AH					; AL = original scan code
	CMP	AL, 0FFH 					; check for Detection Error/Overrun
	JZ	INT_KB_MEEP_DONE				; if overrun, meep and exit
	MOV	DS, CX					; DS = BIOS Data Area
	MOV	DX, CS					; ES = BIOS code segment
	MOV	ES, DX
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
	JZ	KB_INT_CHECK_FN_KEY_DONE		; no control keys held
	ADD	AH, 2DH					; adjust to ALT
	TEST	DL, MASK K1AL				; is it ALT?
	JNZ	KB_INT_PUT_BUFFER_2			; if so, put in buffer
	SUB	AH, 2DH-23H					; adjust to CTRL
	TEST	DL, MASK K1CT				; is CTRL?
	JNZ	KB_INT_PUT_BUFFER_2			; if so, put in buffer
	SUB	AH, 23H-19H					; adjust to shift
KB_INT_PUT_BUFFER_2:					; fit short jumps above
	JMP	KB_INT_PUT_BUFFER

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
	MOV	BIOS_BREAK, KBBRK <1>			; BIOS break flag
	INT	1BH						; call BIOS Break handler
	JMP	SHORT INT_KB_DONE_2

;----------------------------------------------------------------------------;
; Is Ctrl-NumLock (Pause)?
;
INT_KB_CHECK_CTRL_NUM:
	CMP	AL, 45H					; is Num Lock key?
	;CMP	AL, 35H					; key pad / (for testing)
	JZ	INT_KB_SET_PAUSE				; if not, put in Pause

;----------------------------------------------------------------------------;
; 3. Handle numeric keypad entry according to the following:
;
;	Num	Shift	ASCII	Scan
; 	0	0	0	52h	5230 0020
;	0	1	'0'	52h	5200 80A2
;	1	0	'0'	52h	5200 8000
;	1	1	0	52h	5200 8080
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
	TEST	DL, MASK K1LS OR MASK K1RS		;  behavior and jump ahead
	JZ	KB_INT_UC					; jump if no shift held
	JMP	SHORT KB_INT_SHIFT

;----------------------------------------------------------------------------;
; KB Ctrl-NumLock Screen Pause
;----------------------------------------------------------------------------;
INT_KB_SET_PAUSE:
	MOV	BX, OFFSET KB_FLAGS2			; (-1 byte to use indirect)
	OR	BYTE PTR [BX], MASK K2PA		; set PAUSE flag

				IF CGA_SNOW_REMOVE GT 0
;----------------------------------------------------------------------------;
; Make sure CGA is not currently being blanked
;
	CALL	INT_10_IS_CGA80				; ZF = 1 if CGA 80 col
	JNZ	INT_KB_PAUSE_LOOP				; jump if not CGA 80 col
	MOV	AL, VID_MODE_REG				; get default CGA control reg
	MOV	DX, CGA_CTRL				; DX = CGA control port 03D8h
	OUT	DX, AL					; enable video signal
				ENDIF

;----------------------------------------------------------------------------;
; Loop until Pause flag is cleared
;
INT_KB_PAUSE_LOOP:
	HLT							; be a good neighbor
	NOP							; let another interrupt happen
	TEST	BYTE PTR [BX], MASK K2PA		; check the Pause flag
	JNZ	INT_KB_PAUSE_LOOP				; loop until clear
INT_KB_DONE_2:
	JMP	SHORT INT_KB_DONE				; exit INT

;----------------------------------------------------------------------------;
; Emit a feeble meep and exit
;
INT_KB_MEEP_DONE:
	CALL	MEEP
	JMP	SHORT INT_KB_DONE				; exit INT

KB_INT_IS_NUM_DONE:

;----------------------------------------------------------------------------;
; 4. Do scan code to ASCII translation
;----------------------------------------------------------------------------;
KB_INT_CHAR:						; is a regular key ?
	SHL	AL, 1						; align index for table
			IF KB_FILTER_SC
	CMP	AL, 70H * 2					; is make/break code valid?
	JAE	INT_KB_DONE					; if so, discard key and exit
			ENDIF
	TEST	DL, MASK K1LS OR MASK K1RS OR MASK K1AL	; is either shift key or ALT already pressed?
	JNZ	KB_INT_UC					; if so, use uppercase table
KB_INT_SHIFT:
	INC	AX 						; if not shifted, increment
KB_INT_UC:							;  one to use lower case
	MOV	BX, OFFSET KEY_SCAN_TBL
	XLAT	CS:[BX]					; ASCII key in AL = CS:BX[AL]
	TEST	AL, AL					; a is flag key code?
	JNS	KB_INT_NOT_FLAG
	JMP	INT_KB_IS_FLAG
KB_INT_NOT_FLAG:
	TEST	AH, AH					; test high bit of scan code
	JS	INT_KB_DONE					; if set, it is an unhandled break code
KB_INT_IS_CAPS:
	TEST	DL, MASK K1CL				; is CAPS LOCK on?
	JZ	KB_INT_IS_CAPS_DONE
IS_ALPHA:							; CF if AL is not [A-Za-z]
	PUSH	AX						; save original AL
	OR	AL, 'a'-'A'					; lowercase it for comparison
	CMP	AL, 'a'					; is less than 'a'?
	JB	IS_ALPHA_DONE				; CF if not alpha
	CMP	AL, 'z'+1					; is greater than 'z'?
	CMC							; CF if not alpha
IS_ALPHA_DONE:
	POP	AX						; restore original AL
	JC	KB_INT_IS_CAPS_DONE			; jump if not alpha
	XOR	AL, 'a'-'A'					; otherwise, toggle case

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
	JZ	KB_INT_IS_CTRL_DONE			; jump if not
	JMP	INT_KB_CTRL					; otherwise, CTRL is held

;----------------------------------------------------------------------------;
; Handle Shift-PrtSc
;
KB_INT_PRTSC:
	INT	5H						; call print screen handler
	JMP	SHORT INT_KB_DONE

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
; Store AX in keyboard buffer
;
KB_INT_PUT_BUFFER:
	MOV	DI, KB_BUF_TL 				; DI = tail ptr
	LEA	SI, [DI][2]					; SI = next (maybe)
	CMP	SI, KB_BUF_END_B				; is next >= end of buffer?
	JB	KB_INT_CHECK_FULL 			; if not, check if buffer is full
	MOV	SI, OFFSET KB_BUF 			; otherwise, wrap to first address
KB_INT_CHECK_FULL:
	CMP	SI, KB_BUF_HD 				; next == head?
	JE	INT_KB_MEEP_DONE				; Beep if ZF - buffer is full
	MOV	[DI], AX 					; buffer[head] = AX
	MOV	KB_BUF_TL, SI 				; tail = next

;----------------------------------------------------------------------------;
; Restore registers and exit
;
INT_KB_DONE:
	POPX	ES, DS
			IF CPU_TYPE EQ CPU_V20
	POPA							; restore used registers
			ELSE
	POPX	SI, DI, DX, CX, BX			; restore used registers
			ENDIF
	POP	AX
	IRET

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
	JB	INT_KB_NOT_ALT_000			; jump if less than 0
	CMP	BL, 9
	JA	INT_KB_NOT_ALT_000			; jump if above 9

INT_KB_IS_ALT_000:
	XCHG	AX, BX					; AL = input byte, save AX
	MOV	AH, KB_ALT					; AH = partial working byte
	AAD							; AL = AL + ( AH * 10 )
	MOV	KB_ALT, AL					; save new working byte to BDA
	XCHG	AX, BX					; restore AH, AL = 0
	JMP	SHORT INT_KB_DONE				; interrupt complete

;----------------------------------------------------------------------------;
; 8. Check for ALT modified chars that are skipped
; Uses table INT_KB_ALT_SKIP
;
INT_KB_NOT_ALT_000:
	MOV	DI, OFFSET INT_KB_ALT_SKIP
	MOV	CL, 10					; L_INT_KB_ALT_SKIP
	XCHG	AH, AL
	REPNE SCASB						; is in table?
	XCHG	AH, AL
	JNZ	KB_INT_IS_ALT_DONE			; if not found, continue
INT_KB_DONE_1:
	JMP	SHORT INT_KB_DONE				; if found, skip

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
	MOV	CL, L_INT_KB_CTRL_ASC_TBL		; length of table
	MOV	SI, OFFSET INT_KB_CTRL_ASC_TBL
INT_KB_CTRL_ASC_TBL_LOOP:
	LODS	WORD PTR CS:[SI]				; AH = scan code, AL = new ASCII
	CMP	AH, BH					; scan code match?
	LOOPNE INT_KB_CTRL_ASC_TBL_LOOP		; if not keep looping until end
	JNZ	INT_KB_CTRL_ASC_TBL_DONE		; no matches, restore AX and continue
	CMP	CL, L_INT_KB_CTRL_SCAN_TBL		; was first list segment?
	JG	INT_KB_CTRL_NO_DONE			; if so, match found and AX is set, exit
	MOV	AH, 0						; ASCII code 0
	XCHG	AL, AH					; AH = scan code, AL = 0
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
	JNA	INT_KB_DONE					; skip 27-29

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
	JMP	SHORT INT_KB_DONE_1			; don't return 2-35?

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
INT_KB_CTRL_ALT:
	CMP	AH, 53H					; is Ctrl-Alt-Del?
			IF IS_TURBO
	JNZ	INT_KB_CTRL_ALT_1				; if not check for turbo hotkey
			ELSE
	JNZ	INT_KB_CTRL_NO_DONE			; put in buffer as-is and exit
			ENDIF

;----------------------------------------------------------------------------;
; Handle Ctrl-Alt-Del (Warm reboot)
;
INT_KB_CTRL_ALT_DEL:
			IF WARM_ENABLE EQ 1
	MOV	WARM_FLAG, WARM_BOOT			; set warm boot flag
			ELSE
	MOV	WARM_FLAG, COLD_BOOT			; clear warm boot flag
			ENDIF

			IF CPU_TYPE	EQ CPU_V20
	PUSH	OFFSET BOOT_WARM				; ret address is warm reboot
	JMP	BEEP						; beep and return to reboot
			ELSE
	CALL	BEEP						; BEEP on ctrl-alt-del
	JMP	BOOT_WARM					; warm reboot
			ENDIF

			IF IS_TURBO
;----------------------------------------------------------------------------;
; 10. Handle Ctrl-Alt but not Del (only Turbo hotkey)
;
INT_KB_CTRL_ALT_1:

;----------------------------------------------------------------------------;
; Is Turbo speed toggle Ctrl-Alt-+ hotkey?
;
	CMP	AH, 4EH					; numeric pad + key
	JNZ	INT_KB_CTRL_NO_DONE

;	;CMP	AH, 4AH					; numeric pad - key
;	;JZ	INT_KB_TURBO_MINUS

;----------------------------------------------------------------------------;
; Handle Turbo speed mode toggle
;
INT_KB_TOGGLE_TURBO PROC
			IF ARCH_TYPE EQ ARCH_TD3300
	IN	AL, TD_TURBO				; read current state
				IF ARCH_SUB_TYPE EQ ARCH_NEST
	TEST	AL, MASK D11SF				; turbo on? (NZ = turbo)
				ELSE
	CMP	AL, MASK TDSS				; turbo on? (NZ = turbo)
				ENDIF
			ELSE
				IF ARCH_TYPE EQ INIT_V40
	MOV	DX, V40_WCR1				; V40 W/S register
	IN	AL, DX					; FF = slow, 0 = Turbo
	NOT	AL						; flip bits
				ELSE
	IN	AL, PPI_B					; read standard PPI register
				ENDIF				; /IF ARCH_TYPE EQ INIT_V40
	TEST	AL, MASK PBTB				; is in Turbo mode?
			ENDIF					; /IF ARCH_TYPE EQ ARCH_TD3300
	CALL	MEEPMEEP_Z					; two meeps if to high (ZF)
								; one meep if to low (NZ)
	CALL	TOGGLE_TURBO				; toggle speed setting
	JMP	SHORT INT_KB_DONE_3			; done with keyboard
INT_KB_TOGGLE_TURBO ENDP
			ENDIF

;----------------------------------------------------------------------------;
; 5. Is a flag key?
;----------------------------------------------------------------------------;
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
;----------------------------------------------------------------------------;
_KB_FLAGS2	EQU	BYTE PTR[BX]			; Use index addressing
_KB_FLAGS1	EQU	_KB_FLAGS2[-1]			;  for byte savings

INT_KB_IS_FLAG PROC
	MOV	BX, OFFSET KB_FLAGS2			; BX = KB_FLAGS2
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
	JNS	INT_KB_ICNS_MAKE				; if not, jump to make

;----------------------------------------------------------------------------;
; Handle KB_FLAGS2 for Ins, Caps, Num, Scroll Lock for both make and break
;
INT_KB_ICNS_BREAK:
	NOT	AL
	AND	_KB_FLAGS2, AL
	JMP	SHORT	INT_KB_DONE_3
INT_KB_ICNS_MAKE:
	OR	_KB_FLAGS2, AL				; set flag in KB_FLAGS2

;----------------------------------------------------------------------------;
; Otherwise toggle the flag for Ins, Caps, Num, Scrl.
;
; Note: The Ins key is treated as a key press with code 5200H.
;
INT_KB_FLAG_TOGGLE:
	XOR	_KB_FLAGS1, AL				; toggle flag
	TEST	AL, MASK K1IN				; is insert key?
	MOV	AL, 0
	JNZ	INT_KB_PUT_BUFFER_2			; pass through as a key if so
INT_KB_DONE_3:
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
	XOR	_KB_FLAGS2, AL				; toggle flag
	MOV	AL, CL					; restore AL

INT_KB_NOT_ICNS_1:
	DEC	BX						; _KB_FLAGS2 = KB_FLAGS1
	TEST	AH, AH					; is a break code?
	JS	INT_KB_FLAG_CLEAR				; if so, clear flag
	OR	_KB_FLAGS2, AL				; set flag
	JMP	SHORT INT_KB_DONE_3			; done

INT_KB_FLAG_CLEAR:
	NOT	AL						; invert mask
	AND	_KB_FLAGS2, AL				; clear flag
	CMP	CL, MASK K1AL				; was it ALT key?
	JNZ	INT_KB_DONE_3				; if not, done

INT_KB_IS_FLAG ENDP

;----------------------------------------------------------------------------;
; ALT has just been released
;----------------------------------------------------------------------------;
; Check if there a partial value of ALT+000 (ALT-GR) numpad entry work byte?
;
INT_KB_ALT_BREAK:
	MOV	AL, KB_ALT
	TEST	AL, AL					; is ALT working sum 0?
	JZ	INT_KB_DONE_3				; if so, end
	MOV	AH, 0						; Scan code is 0
	MOV	KB_ALT, AH					; clear ALT byte working sum
INT_KB_PUT_BUFFER_2:
	JMP	KB_INT_PUT_BUFFER				; use value as output char

;----------------------------------------------------------------------------;
; Keyboard scancode mapping tables
;----------------------------------------------------------------------------;
; For each scan code this table contains ASCII characters. The first byte is
; the shifted (shift held) ASCII char, followed by the non-shifted ASCII char.
;
; Flag chars (noted by *) return their scan code with most sig bit set 
; (also their break code).
;----------------------------------------------------------------------------;
KEY_SCAN_TBL	LABEL BYTE
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
; for the F1-F10 keys since those scan codes are handled separately.
; This space can be used as long as exactly 20 bytes is left to maintain the
; table index. Left commented-out below for reference:
;	DW	10 DUP(0) 				; 3B-44H	F1-F10

;----------------------------------------------------------------------------;
; Table for scan codes that are keys that set flags.
; The byte's index corresponds to the flag bit position in BDA's KB_FLAGS1.
; Length: 8 bytes
;
KEY_FLAG_ON_TBL	LABEL BYTE	;                            ICNSATLR
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
INT_KB_ALT_SKIP	LABEL BYTE
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

;----------------------------------------------------------------------------;
; Resume scancode table at 45H (word aligned)
;
		ORG	KEY_SCAN_TBL + 45H * 2
KEY_SCAN_TBL_HIGH	LABEL BYTE
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

			IF CASSETTE EQ 1
;----------------------------------------------------------------------------;
; Cassette equates for indirect memory references to save code bytes
;----------------------------------------------------------------------------;
_CAS_CRC		EQU	WORD PTR[SI]
_CAS_PREV		EQU	BYTE PTR[SI][CAS_PREV-CAS_CRC]
_CAS_TIME_CNT	EQU	WORD PTR[SI][CAS_TIME_CNT-CAS_CRC]
_BIOS_BREAK		EQU	BYTE PTR[SI][BIOS_BREAK-CAS_CRC]

;----------------------------------------------------------------------------;
; CAS_CRC_ADD: Add current bit to CRC message
;----------------------------------------------------------------------------;
; Input:
;	CF = bit to add
;	SI = OFFSET CAS_CRC
;----------------------------------------------------------------------------;
; This is (effectively) CRC16-CCITT as used by IBM for SDLC/HDLC. It uses a
; 0FFFFh initial/preset value, 1021h polynomial and has an expected residue
; value of 01D0Fh.
;
; cf = ( ( crc & 0x8000 ) >> 15 ) ^ CF;
; if ( cf ) {
;	crc = crc ^ (0x1021 >> 1);
; }
; crc = crc << 1 | cf;
; return crc;
;
; https://stackoverflow.com/questions/62771192/crc16-ccitt-calculation
; http://bitsavers.trailing-edge.com/pdf/ibm/datacomm/GA27-3093-3_SDLC_Concepts_Jun86.pdf
;----------------------------------------------------------------------------;
CAS_CRC_PRE		EQU	0FFFFh	; Cassette CRC16-CCITT preset value
CAS_CRC_RES		EQU	01D0Fh	; Cassette CRC16-CCITT residue value
CAS_CRC_POLY 	EQU 	01021h	; Cassette CRC16-CCITT polynomial

CAS_CRC_ADD PROC
	XCHG	AX, _CAS_CRC		; get working CRC, save AX
	RCR	AX, 1				; set up for RCL
	RCL	AX, 1				; OF = MSB(AX) != CF
	CLC					; CF = OF
	JNO	CAS_CRC_SHIFT		; if OF: AX = AX XOR 0810h
	XOR	AX, CAS_CRC_POLY SHR 1	; divide by polynomial (already shifted)
	STC					; CF = OF
CAS_CRC_SHIFT:
	ADC	AX, AX			; add bit to working CRC value
	XCHG	_CAS_CRC, AX		; store working CRC, restore AX
	RET
CAS_CRC_ADD ENDP
			ENDIF			; IF CASSETTE EQ 1

;
; 7 BYTES HERE / 6 BYTES HERE 5150
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
;  Output:
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

;----------------------------------------------------------------------------;
; Use indexed addressing to DI = FD_LAST_OP for byte savings.
;
_FD_LAST_OP		EQU	BYTE PTR [DI]				; FD_LAST_OP
_FD_MOTOR_ST	EQU	_FD_LAST_OP[FD_MOTOR_ST-FD_LAST_OP]	; FD_MOTOR_ST
_FD_MOTOR_CT	EQU	_FD_LAST_OP[FD_MOTOR_CT-FD_LAST_OP]	; FD_MOTOR_CT
_FD_CAL_ST		EQU	_FD_LAST_OP[FD_CAL_ST-FD_LAST_OP]	; FD_CAL_ST
_FD_TRACK		EQU	_FD_LAST_OP[FD_TRACK-FD_LAST_OP]	; FD_TRACK
_FD_MEDIA_ST	EQU	_FD_LAST_OP[FD_MEDIA_ST-FD_LAST_OP]	; FD_MEDIA_ST
_FD_TIMER		EQU	_FD_LAST_OP[TIMER-FD_LAST_OP]		; TIMER
_FDC_LAST_ST	EQU	[DI][FDC_LAST_ST-FD_LAST_OP]		; FDC_LAST_ST

		ORG 0EC59H
INT_13 PROC
		ASSUME DS:_BDA
	STI 						; enable interrupts
	CLD
	PUSHX	DS, DI				; save caller registers
	MOV	DI, SEG _BDA			; DS = BDA
	MOV	DS, DI
	INC	DI					; DI = FD_LAST_OP throughout
	AND	_FD_MOTOR_ST, NOT MASK FWRT	; clear write operation flag
	CMP	AH, 1 				; AH = 1?
	JE	INT_13_1 				; AH = 1, jump to Status
	PUSHX	DX, CX, BX				; save caller registers
	MOV	_FD_LAST_OP, FDC_ST_OK		; clear last operation
			IF FDC_ENABLE EQ 1
	JB	INT_13_0 				; AH = 0, jump to Reset
	CMP	DL, 3 				; is drive number > 3?
	JA	INT_13_BAD_CMD 			; if so, exit
	CMP	AH, 6 				; AH = 2 through 5?
	JB	INT_13_2_5 				; jump to FDC RWVF command
			ENDIF
INT_13_BAD_CMD:
	INC	_FD_LAST_OP				; otherwise return "bad command" (1)
INT_13_DONE:
	MOV	AH, _FD_LAST_OP 			; AH = last operation status
INT_13_SET_MOTOR_CT:
	XCHG	AX, BX				; save AL
	MOV	AL, DBT.FMCT 			; INT_1E[2] = motor shutoff counter
	CALL	INT_1E_PARAM 			; AL = shutoff counter value (37)
	MOV	FD_MOTOR_CT, AL 			; update in BDA
	XCHG	AX, BX				; restore AL
INT_13_EXIT:
	POPX	BX, CX, DX				; restore caller registers
INT_13_EXIT_1:
	POPX	DI, DS				; restore caller registers
	CMP	AH, FDC_ST_OK+1			; check AH for error (CF = AH < 1)
	CMC   					; invert CF for return (CF = ! CF)
	IRET_F 					; return from int with current flags

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
;	0 0 0 0	 	- 			AND with 1111, jump if AL = 0
;	1 x x x		3			TEST bit 1000, if non-zero then AL = 3
;	0 1 0 x		2 			Shift right once and AL will be correct
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
	AND	AL, MASK FMOT			; isolate motor status flags
	JZ	INT_13_0_2				; jump if no motors are on, default to 0

;----------------------------------------------------------------------------;
; One motor is on (according to BDA). Convert motor run flags to binary number
; since FDC requires a drive index for the reset.
;
	SHR	AL, 1					; disregard low bit (will be 0 either way)
	TEST	AL, MASK FMOT3 SHR 1		; test for drive 3?
	JZ	INT_13_0_1				; if not drive 3, AL is now correct
	MOV	AL, 3 				; otherwise set AL to drive 3
INT_13_0_1:
			IF CPU_TYPE	EQ CPU_V20
	ROL4	_CH					; CH(h) = FD_MOTOR_ST(l), CH(l) = AL(l)
							;  = (FD_MOTOR_ST SHL 4) OR (AL AND 0FH)
	MOV	AL, CH				; AL = CH
			ELSE
	MOV	CL, 4 				; move low nibble of FD_MOTOR_ST
	SHL	CH, CL				;  into high nibble of CH
	OR	AL, CH 				; combine nibbles with AL
			ENDIF

;----------------------------------------------------------------------------;
; Reset the controller by holding FDC reset (bit 2) at 0.
; Perform the following memory operations here to satisfy reset timing for FDC:
; - Flag all drives for recalibration (not just the drive in DL)
;
INT_13_0_2:
	OR	AL, MASK FDDMA			; enable DMA & I/O interface, FDC reset
	OUT	DX, AL				; send to FDC
	MOV	_FD_CAL_ST, AH 			; flag all drives for recalibration

;----------------------------------------------------------------------------;
; Re-enable FDC by setting bit 2 to 1.
; Wait for Interrupt (WIF) from FDC
;
	OR	AL, MASK FDCEN			; set FDC enable
	OUT	DX, AL				; send to FDC
	STI 						; enable interrupts
	CALL	FDC_WAIT_SENSE			; wait for FDC to signal interrupt
	JC	INT_13_0_RESET_BAD		; jump if FDC read/sense error
	CMP	AL, FDC_ST0 < 11B >		; was successful reset?
	JZ	INT_13_0_RESET_DONE		; jump if success, AH = 0
INT_13_0_RESET_BAD:
	MOV	AH, FDC_ST_ERR_FDC		; otherwise, controller failure
INT_13_0_RESET_DONE:
	MOV	_FD_LAST_OP, AH			; set last result
	JNZ	INT_13_SET_MOTOR_CT		; exit on error with AH already set

;----------------------------------------------------------------------------;
; (Re)send Specify bytes to FDC
;
	MOV	AL, FDC_CMD_SPEC 			; [0] FDC Specify command
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	INT_13_0_DONE
	MOV	AL, DBT.SRT				; [1] step rate time, head unload time
	CALL	FDC_SEND_PARAM
	JC	INT_13_0_DONE
	MOV	AL, DBT.HLT_ND			; [2] head load time (01H), DMA mode (ND)
	CALL	FDC_SEND_PARAM

;----------------------------------------------------------------------------;
; Exit and return with AL = 0
;
INT_13_0_DONE:
	MOV	AL, 0					; 0 sectors read
	JMP	SHORT INT_13_DONE
INT_13_0 ENDP

;----------------------------------------------------------------------------;
; INT 13, 1: Get disk status
;----------------------------------------------------------------------------;
; Output: AL and AH = status of last operation
;----------------------------------------------------------------------------;
INT_13_1 PROC
	MOV	AL, _FD_LAST_OP 			; AL = last operation status
	MOV	AH, AL				; AH = last operation status
	JMP	SHORT INT_13_EXIT_1
INT_13_1 ENDP

;----------------------------------------------------------------------------;
; DMA page boundary overrun
;
FDC_DMA_BOUND:
	OR	_FD_LAST_OP, FDC_ST_DMA_64K	; DMA boundary error
	STC						; re-set CF
	JMP	SHORT FDC_INIT_DMA_EXIT		; rebalance stack and exit

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
FDC_CMD_TBL LABEL BYTE
	DB	FDC_CB <1,,1,FDC_CMD_RD>	; 2 FDC Read - MT, MFM, Skip deleted
	DB	FDC_CB <1,,0,FDC_CMD_WR>	; 3 FDC Write - Multi-Track, MFM
	DB	FDC_CB <1,,1,FDC_CMD_RD>	; 4 FDC Verify - MT, MFM, Skip deleted
	DB	FDC_CB <0,,0,FDC_CMD_FMT>	; 5 FDC Format - Single-Track, MFM

INT_13_2_5 PROC
	XCHG	AL, AH				; AL = function, AH = sectors to read
	PUSH	AX					; save function, sector count
	PUSH	DX					; save head, drive

;----------------------------------------------------------------------------;
; Get DMA mode byte
;
	MOV	DH, DMA_MR <1,0,0,1,2> 		; set DMA read mode 1 (AH = 2)
	CMP	AL, 2					; is read?
	JE	INT_13_2_5_SETUP_DMA		; if so, proceed to setup
	MOV	DH, DMA_MR <1,0,0,0,2> 		; set DMA verify mode 0 (AH = 4)
	CMP	AL, 4					; is verify?
	JE	INT_13_2_5_SETUP_DMA		; if so, proceed to setup
	MOV	DH, DMA_MR <1,0,0,2,2> 		; else DMA write/format mode 2 (AH = 3,5)
	OR	_FD_MOTOR_ST, MASK FWRT		; turn on write flag
INT_13_2_5_SETUP_DMA:
	MOV	AL, DH				; AL = DMA mode, AH = sectors to read
	CALL	FDC_SEEK 				; Turn on motor, CH = track, DL = drive
	JC	INT_13_2_5_SEEK_ERR		; exit if seek error
							; fall through to set up DMA

;----------------------------------------------------------------------------;
; FDC_INIT_DMA: Configure DMA channel 2 for FDC operation
;----------------------------------------------------------------------------;
; Input:
;  AH = sectors to read
;  AL = DMA mode:
;	01000110 (46H) - Read
;	01000010 (42H) - Verify
;	01001010 (4AH) - Write
; 	01 			; Mode: Single mode select
; 	  0  			; Address increment
;	   0 			; Auto-initialization disable
;	    xx		; 00=verify, 10=write, 01=read, 11=unused
;	      10		; Channel 2 select
;  ES:BX = pointer to buffer
;
; Output:
;  CF = 0 success, 1 if error DMA exceeds segment
;----------------------------------------------------------------------------;
; Things you must do:
;	- Calculate # of bytes to transfer by multiplying AL (sectors) by
;		sector size in INT 1E Disk Base Table.
;	- Calculate physical memory address from ES:BX and normalize to
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
;----------------------------------------------------------------------------;
; References:
;  https://pdf1.alldatasheet.com/datasheet-pdf/view/127822/AMD/8237A.html
;  https://wiki.osdev.org/ISA_DMA#Floppy_Disk_DMA_Initialization
;  https://stackoverflow.com/questions/52396915/how-to-write-assembly-language-to-make-dma-works
;  https://userpages.umbc.edu/~squire/intel_book.pdf
;----------------------------------------------------------------------------;
FDC_INIT_DMA:
	PUSH	CX					; save track / sector
	MOV	DX, ES 				; get and shift ES by one nibble
			IF CPU_TYPE EQ CPU_V20
	ROL	DX, 4					; V20 only
			ELSE
	MOV	CL, 4					; DL = lowest and highest nibble of ES
	ROL	DX, CL				; DH = middle nibbles
			ENDIF
	OUT	DMA_MODE, AL			; write to DMA mode reg (port 0BH)
	XOR	AL, AL				; AX = sectors to read << 8
	XCHG	AX, CX				; CX = sectors, AX = scratch
	MOV	AL, DBT.FBPS			; get bytes/sector param (0=128, 1=256, 2=512, 3=1024)
	CALL	INT_1E_PARAM			; AL = shift count (default 2 => 512)
	XCHG	AX, CX				; AX = sectors, CL = bytes per sector shifts
	SHR	AX, 1					; adjust shift for bytes/sector * 128
	SHL	AX, CL				; AX = bytes to transfer (AX * 2^CL)
	DEC	AX					; AX = bytes to transfer - 1
	XCHG	AX, CX				; CX = bytes to transfer - 1
	MOV	AL, DL				; AL = lowest and highest nibble of ES
	AND	AL, 0FH				; AL = only high nibble of ES
	AND	DL, 0F0H				; DX = low three nibbles of ES (shifted left 1 nibble)
	ADD	BX, DX				; BX = DMA start offset for transfer
	ADC	AL, 0					; AL = DMA page
	MOV	DX, BX				; check that buffer offset + length does not exceed segment
	ADD	DX, CX				; DX = DMA end offset, test for boundary overflow
	JC	FDC_DMA_BOUND			; error if DMA access across 64k boundary
	CLI						; Disable interrupts
	OUT	DMA_FF, AL				; DMA clear flip-flop (port 0CH) (any value)
	OUT	DMA_P_C2, AL 			; set DMA Channel 2 Page Address Register (port 81H)
	XCHG	AX, BX				; AL = address low byte, AH = high byte
	OUT	DMA_2_A, AL				;
	XCHG	AL, AH 				; AH = address low byte, AL = high byte
	OUT	DMA_2_A, AL				;
	XCHG	AX, CX				; AL = byte/count low byte, AH = high byte
	OUT	DMA_2_C, AL				;
	XCHG	AL, AH				; AH = byte/count low byte, AL = high byte
	OUT	DMA_2_C, AL
	STI						; Enable interrupts
	MOV	AL, DMA_SMR <0, 2>		; DMA clear single channel 2 mask bit
	OUT	DMA_MASK, AL			; Unmask DMA Channel 2 (port 0AH)
FDC_INIT_DMA_EXIT:
	POP	CX					; CL = sector, CH = track
INT_13_2_5_SEEK_ERR:
	POP	DX 					; DL = drive, DH = head
	POP	AX					; AL = function, AH = sectors to read
	JC	INT_13_0_DONE			; exit if DMA error with AL = 0

;----------------------------------------------------------------------------;
; Get FDC command byte
;
	PUSH	AX					; AL = function (2-5), AH = sectors
	MOV	BX, OFFSET FDC_CMD_TBL[-2]	; BX = cmd byte table (2-indexed)
	XLAT	CS:[BX]				; AL = FDC cmd byte
	POP	BX					; BL = function, BH = sectors

;----------------------------------------------------------------------------;
; FDC_RWVF: read, write, verify or format sectors
;----------------------------------------------------------------------------;
; Input:
;	AL = FDC command byte
;	BL = INT 13h function number
;	BH = sectors to read
;	DL = drive (0-3)
;	DH = head (0-1)
;----------------------------------------------------------------------------;
	CALL	FDC_SEND 				; [0] send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, DH				; AL/DH = head, DL=drive
	SHL	AL, 1					; [1] head / drive byte: 
	SHL	AL, 1					;  xxxxx     ; unused
	OR	AL, DL 				;       h    ; head number (bit 3)
	AND	AL, MASK FC1HD OR MASK FC1DS	;        dd  ; drive number (bit 1,2)
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	CMP	BL, 5					; is format?
	JE	FDC_FORMAT

;----------------------------------------------------------------------------;
; FDC_RWV: read, write or verify sectors
;----------------------------------------------------------------------------;
; Input:
;	CH = track/cylinder number (0-39)
;	CL = sector number (1-17)
;	DH = head number (0-1) (bounds not checked)
;
; Output:
;	AL = number of sectors read, written or verified
;----------------------------------------------------------------------------;
FDC_RWV PROC
	MOV	AL, CH 				; [2] cylinder number
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, DH 				; [3] head number
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, CL 				; [4] sector number
	CALL	FDC_SEND 				; send command in AL, CF if error
	JC	FDC_RWV_ERR
	MOV	AL, DBT.FBPS			; [5] bytes per sector
	CALL	FDC_SEND_PARAM			; 2 = 512 bytes
	JC	FDC_RWV_ERR
	MOV	AL, DBT.SPT				; [6] end of track (last sector in track)
	CALL	FDC_SEND_PARAM
	JC	FDC_RWV_ERR
	MOV	BL, AL				; BL = sectors per track
	MOV	AL, DBT.SGAP			; [7] sector gap length
	CALL	FDC_SEND_PARAM
	JC	FDC_RWV_ERR
	MOV	AL, DBT.LSEC			; [8] data length (if cmd byte 5==0)

;----------------------------------------------------------------------------;
; Send last param and wait for status
;
FDC_RWV_SEND_WAIT:
	CALL	FDC_SEND_PARAM
	JC	FDC_RWV_ERR
	CALL	FDC_WAIT_STATUS			; wait for WIF and get status
			IF FDC_ERR_SEC_CT NE 1
	JC	FDC_RWV_ERR				; if error, report 0 sectors read
			ENDIF
							; fall through for FDC SEC COUNT

;----------------------------------------------------------------------------;
; FDC_SEC_COUNT: get the number of sectors read/verified/written
;----------------------------------------------------------------------------;
; Input:
;	BL = sectors per track (1-9)
;	BH = number of sectors to read
;	CH = start track/cylinder number (0-39)
;	CL = start sector number (1-17)
;	DH = head number (0-1)
; Output:
;	AL = sectors transferred
;	AH = preserved
;
; Note: If the operation finishes at the last head/sector of a track, 
;	FDC will report the head/track/sector position to be the beginning 
;	of the next track.
;----------------------------------------------------------------------------;
FDC_SEC_COUNT:
	MOV	AL, FDC_LAST_ST.SEC		; AL = FDC reported end sector
	MOV	DL, CH				; DL = start track
	CMP	DX, WORD PTR _FDC_LAST_ST.CYL	; rolled to next head or track?
	JE	FDC_SEC_COUNT_SAME		; if not, ended on the same head/track

;----------------------------------------------------------------------------;
; Command has ended on a different head or track. Calculate the correct
; number of sectors spanned.
;
	CMP	DH, _FDC_LAST_ST.HEAD		; end on same head but different track?
	JNE	FDC_SEC_COUNT_SAME_CYL		; if so, has spanned a full head
	ADD	AL, BL				; add two tracks worth of sectors
FDC_SEC_COUNT_SAME_CYL:
	ADD	AL, BL				; add ending sector
FDC_SEC_COUNT_SAME:
	SUB	AL, CL				; AL = ending - starting = sec read
	;CMP	AL, BH				; verify requested # of sectors was
							; # actually read (not necessary).

FDC_RWV ENDP					; fall through for exit

;----------------------------------------------------------------------------;
; Done with all disk operations and return AL
;
INT_13_2_5_EXIT:
	JMP	INT_13_DONE

;----------------------------------------------------------------------------;
; Clear AL and exit on any read/write error
;
FDC_RWV_ERR:
FDC_FORMAT_ERR:
	JMP	INT_13_0_DONE			; on error: exit with sectors read = 0

;----------------------------------------------------------------------------;
; INT 13, 5: Format Track
;----------------------------------------------------------------------------;
; Input:
;	AH = 05
;	AL = interleave value (XT only) / sectors per track
;	CX = track/cylinder number (see below for format)
;	DL = head number  (0-15 dec.)
;	ES:BX = pointer to block of "track address fields" (provided by DOS)
;----------------------------------------------------------------------------;
FDC_FORMAT PROC
	MOV	AL, DBT.FBPS			; [2] bytes per sector
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	MOV	AL, DBT.SPT				; [3] sectors per track
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	MOV	AL, DBT.FGAP			; [4] format gap length
	CALL	FDC_SEND_PARAM
	JC	FDC_FORMAT_ERR
	MOV	AL, DBT.FFILL			; [5] format fill byte
	MOV	CL, 1					; format always starts at sector 1
	JMP	SHORT FDC_RWV_SEND_WAIT		; send, wait for WIF and get status
FDC_FORMAT ENDP

INT_13_2_5 ENDP

;----------------------------------------------------------------------------;
; FDC_SEEK: Seek to track
;----------------------------------------------------------------------------;
; Input:
;	CH = track
;	DL = drive (0-3) (bounds not checked)
;	DI = OFFSET FD_LAST_OP
;----------------------------------------------------------------------------;
FDC_SEEK PROC
	PUSH	AX
	PUSH	BX
	CALL	FDC_RECAL 				; recalibrate if needed
	JC	FDC_SEEK_RECAL_ERR		; exit if recal error

			IF FDC_ADV_SEEK EQ 1
;----------------------------------------------------------------------------;
; If FDC_ADV_SEEK, the current track where the head is positioned is saved in
; the BDA so that a subsequent operation on the same track will not require
; another seek. This may result in performance improvements on sequential reads.
;
	JNZ	FDC_CHECK_SEEK			; recal not needed, check if seek

;----------------------------------------------------------------------------;
; Recal was executed and now on track 0. Just do a head settle if it was
; the destination track.
;
	TEST	CH, CH				; destination track 0?
	JZ	FDC_SEEK_SETTLE			; if so, skip to head settle time

;----------------------------------------------------------------------------;
; Check BDA to see if head is already positioned at the destination track.
;
FDC_CHECK_SEEK:
	XOR	BH, BH
	MOV	BL, DL				; BX = drive #
	CMP	_FD_TRACK[BX], CH			; compare last track seek to dest
	JE	FDC_SEEK_DONE			; already on track - nothing to do
			ENDIF				; end IF FDC_ADV_SEEK

	MOV	AL, FDC_CMD_SEEK			; seek command (0FH)
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_SEEK_ERR
	MOV	AL, DL 				; AL = drive number
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_SEEK_ERR			; necessary?
	MOV	AL, CH 				; AL = track number
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_SEEK_ERR
	CALL	FDC_WAIT_SENSE			; wait for WIF, sense and get status
	JC	FDC_SEEK_ERR
	XOR	AL, FDC_ST0 <01B, 1>		; select abnormal term, seek complete
	AND	AL, FDC_ST0 <01B, 1>		; ZF = abnormal term AND seek complete
	JZ	FDC_SEEK_ERR
			IF FDC_ADV_SEEK EQ 1
	MOV	_FD_TRACK[BX], CH			; save last seeked track (BX = drv #)
			ENDIF

;----------------------------------------------------------------------------;
; Allow time for heads to settle after seek. This may be skipped on emulators.
;
FDC_SEEK_SETTLE:
			IF ARCH_TYPE NE ARCH_EMU
	MOV	AX, DBT.HDST			; AL = HST DBT param, AH = 0
	CALL	INT_1E_PARAM			; AL = head settle time (ms)
	CALL	IO_DELAY_MS_FDC			; delay AX ms
			ENDIF
	CLC						; no error
FDC_SEEK_DONE:
	POP	BX
	POP	AX
	RET

FDC_SEEK_RECAL_ERR:
FDC_SEEK_ERR:
	OR	_FD_LAST_OP, FDC_ST_ERR_SEEK
	STC
	JMP	SHORT FDC_SEEK_DONE
FDC_SEEK ENDP

;----------------------------------------------------------------------------;
; FDC_RECAL: recalibrate drive, if necessary
;----------------------------------------------------------------------------;
; Input:
;	DL = drive to recalibrate (0-3) (bounds not checked)
;	DI = OFFSET FD_LAST_OP
; Output:
;	CF if error
;
; Clobbers: AX, BX (if ADV_SEEK)
;----------------------------------------------------------------------------;
FDC_RECAL PROC
	PUSH	CX

;----------------------------------------------------------------------------;
; FDC_MOTOR_ON: Turn on motor
;----------------------------------------------------------------------------;
; Input:
; 	DL = drive number (0-3) (bounds not checked)
;----------------------------------------------------------------------------;
; Things you must do:
;	- is motor already on? Skip wait for spin up
;	- wait only for writes
;	- check if recalibration is necessary
;----------------------------------------------------------------------------;
FDC_MOTOR_ON:
	MOV	CL, DL 				; move drive number to CL for shift

;----------------------------------------------------------------------------;
; Convert drive number to motor run format
;
	MOV	AX, 110H 				; AH -> RUN_ST, AL -> FDC byte
	SHL	AX, CL 				; shift drive flags
	CLI 						; disable interrupts
	MOV	_FD_MOTOR_CT, 255			; restart timer to max for operation
	MOV	CH, _FD_MOTOR_ST			; get current RUN_ST
	TEST	CH, AH 				; is drive already running?
	JNZ	FDC_DRIVE_STARTED			; skip startup if so
	OR	AL, CL 				; combine drive number to FDC byte
	OR	AL, MASK FDDMA OR MASK FDCEN	; set DMA and controller enable flags
	PUSH	DX					; preserve DX
	MOV	DX, FDC_CTRL			; port 3F2H, FDC Digital Output
	OUT	DX, AL				; turn on motor
	POP	DX
	MOV	AL, CH 				; AL = FD_MOTOR_ST
	MOV	CH, AH				; CH = RUN_ST drive bit field
	AND	AL, NOT MASK FMOT 		; clear motor status of FD_MOTOR_ST
	OR	AL, AH				; combine nibbles, SF if write
	MOV	FD_MOTOR_ST, AL			; write to motor status
	JNS	FDC_DRIVE_STARTED 		; delay for motor spinup if write op

;----------------------------------------------------------------------------;
; Delay using timer tick counter
;
	STI 						; enable interrupts
	MOV	AL, DBT.FMST			; AL = INT_1E[10]
	CALL	INT_1E_PARAM 			; AL = motor startup time (in 125ms)
	CALL	IO_WAIT_MS_125			; wait AL * 125ms

FDC_DRIVE_STARTED:
	AND	CH, MASK FMOT			; isolate drives, remove write flag
	STI 						; ensure interrupts enabled

;----------------------------------------------------------------------------;
; Calibrate drive if necessary
;
	TEST	CH, _FD_CAL_ST 			; 0 means drive is uncalibrated
	JNZ	FDC_RECAL_DONE 			; if drive is calibrated, exit
	MOV	AL, FDC_CMD_RECAL 		; recalibrate command (07H)
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_RECAL_ERR
	MOV	AL, CL 				; AL = drive number
	CALL	FDC_SEND 				; send command, CF if error
	JC	FDC_RECAL_ERR			; (necessary?)
	CALL	FDC_WAIT_SENSE 			; wait for WIF, sense and get status in AL
	JC	FDC_RECAL_ERR
	XOR 	AL, FDC_ST0 <01B, 1>		; select abnormal term, seek complete
	AND	AL, FDC_ST0 <01B, 1>		; ZF = abnormal term AND seek complete
	STC						; presume failure
	JZ	FDC_RECAL_ERR			; jump if error
	OR	_FD_CAL_ST, CH 			; mark drive as calibrated and CLC

			IF FDC_ADV_SEEK EQ 1
;----------------------------------------------------------------------------;
; Save track 0 to BDA FD_TRACK
;
	XOR	BH, BH				; track 0 and set ZF
	MOV	BL, DL				; BX = drive index
	MOV	_FD_TRACK[BX], BH			; save last track seek 0
			ENDIF

FDC_RECAL_ERR:
FDC_RECAL_DONE:
	POP	CX
	RET
FDC_RECAL ENDP

;----------------------------------------------------------------------------;
; FDC_RECV: Wait for FDC ready to send and read next FDC Status byte into AL
;----------------------------------------------------------------------------;
; Timeout is 5 timer ticks = ~275ms.
;
; Input: None
; Output:
;	AL = top of FDC status stack
;	AH = 80H if error, 0 if success
;	CF if timeout or error
;----------------------------------------------------------------------------;
FDC_RECV PROC
	PUSH	BX
	XOR	BX, BX				; flag is 0 if RECV operation
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
;	AH = 80H if error, 0 if success
;	CF and ZF if error
;----------------------------------------------------------------------------;
FDC_SEND PROC
	PUSH	BX
	MOV	BL, 1					; flag is 1 if SEND operation

FDC_SEND_RECV:
	MOV	BH, AL				; save byte to send
	PUSH	CX
	PUSH	DX 					; call-preserve used registers

;----------------------------------------------------------------------------;
; Wait for FDC I/O direction = CPU to FDC and Data Reg Ready
;
	MOV	CX, 5					; CX = # of ticks to wait
	MOV	AH, BYTE PTR TIMER.LW		; get starting tick counter low byte

FDC_SEND_WAIT_POLL:
	MOV	DX, FDC_STAT 			; port 3F4H - FDC Main Status Register
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
	MOV	AL, BYTE PTR TIMER.LW		; get current tick counter
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

;----------------------------------------------------------------------------;
; FDC_WAIT_SENSE: wait for WIF, sense status and get status bytes
;----------------------------------------------------------------------------;
; Output:
;	CF if FDC read/timeout error
;	NZ if result status error
;	AL = FDC_LAST_ST (BDA Floppy drive status)
;	AH = 0 if success, 80H if failure
;----------------------------------------------------------------------------;
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
;	AH = 0 if success, 80H if failure
;----------------------------------------------------------------------------;
FDC_RECV_STATUS PROC
	JC	FDC_WAIT_SENSE_EXIT		; return if timeout error
							; fall through to FDC_RECV_ALL

;----------------------------------------------------------------------------;
; FDC_RECV_ALL: Pop all status bytes from FDC to BDA
;----------------------------------------------------------------------------;
; Check for FDC errors and set FD_LAST_OP if necessary
; Input: DS = BDA (40H), DI = FD_LAST_OP (41H)
; Output: AH = 0 if success, 80H if failure
;----------------------------------------------------------------------------;
FDC_RECV_ALL PROC
	PUSH	ES
	PUSH	CX
	PUSH	DI					; preserve DI (FD_LAST_OP)
	PUSH	DX
	MOV	DX, FDC_STAT
	PUSH	DS					; ES = BDA segment
	POP	ES
	INC	DI					; DI = FDC_LAST_ST (FDC Last Result)
	MOV	CX, SIZE FDC_CSB			; loop up to 7 FDC bytes
FDC_RECV_ALL_LOOP:
	CALL	FDC_RECV				; AL = next byte, AH = 0 if success
	JC	FDC_RECV_ALL_DONE			; CF if failure
	STOSB						; write to BDA

;----------------------------------------------------------------------------;
; Additional delay for FDC to settle
;
		IF IS_TURBO AND UNSAFE_FLOPPY NE 1
	MOV	AL, 20				; delay 372 clocks (~31us at 12MHz,
		ELSE					;  ~37us at 10MHz, ~46us at 8MHz)
	MOV	AL, 10				; delay ~225 clocks (~47us at 4.77)
		ENDIF
FDC_RECV_DELAY:					; [7+19(AX-1)] clocks
	DEC	AX					; [3]
	JNZ	FDC_RECV_DELAY			; [4+16(AX-1)]

;----------------------------------------------------------------------------;
; Check for additional bytes to be read from FDC registers
;
	IN	AL, DX				; DX = 03F4H
	AND	AL, MASK FDRW 			; is FDC R/W command in progress flag?
	LOOPNZ FDC_RECV_ALL_LOOP		; loop until no flag or 7 bytes read
	JNZ	FDC_RECV_FDC_ERR			; command still in progress?
							; AL = 0 (no command in progress) or CX = 0
		IF FDC_ZERO_BDA EQ 1
	REP	STOSB 				; zero out rest of results in BDA
		ENDIF
FDC_RECV_CHECK_ERR:
	MOV	AL, FDC_LAST_ST.SB0 		; AL = last FDC status byte 0
	TEST	AL, MASK ST0CS			; check Last Command Status
FDC_RECV_ALL_DONE:
	POP	DX
	POP	DI					; DI = FD_LAST_OP
	POP	CX
	POP	ES
FDC_WAIT_SENSE_EXIT:
	RET

;----------------------------------------------------------------------------;
; Command still in progress after reading 7 bytes. Return FDC error.
;
FDC_RECV_FDC_ERR:
	MOV	AH, FDC_ST_ERR_FDC		; controller still busy after
	OR	FD_LAST_OP, AH			;  reading max bytes
	STC
	JMP	SHORT FDC_RECV_ALL_DONE
FDC_RECV_ALL ENDP
FDC_RECV_STATUS ENDP
FDC_WAIT_SENSE ENDP

;----------------------------------------------------------------------------;
; FDC_WAIT_STATUS: Wait for WIF, get status bytes and check for error
;----------------------------------------------------------------------------;
FDC_WAIT_STATUS PROC
	CALL	FDC_WAIT_INT 			; wait for WIF
	CALL	FDC_RECV_STATUS			; read FDC status into BDA
							; CF if FDC error, NZ if status error
	JBE	FDC_WAIT_ERR_EXIT_OK		; exit if ZF or CF error

;----------------------------------------------------------------------------;
; FDC_WAIT_STATUS_ERR: Map FDC Command Status Register 1 to BDA error codes
;----------------------------------------------------------------------------;
; Input:
;	AL = Last result from FDC_LAST_ST
; Output:
;	CF if error
;	AH/AL = BDA Floppy drive status
;----------------------------------------------------------------------------;
FDC_WAIT_STATUS_ERR PROC
	TEST	AL, FDC_ST0 < 01B >		; command terminated abnormally?
	MOV	AL, FDC_ST_ERR_FDC		; if not, FDC error
	JZ	FDC_WAIT_STATUS_ERR_DONE
	CBW						; AH = 0
	OR	AH, _FDC_LAST_ST.SB1		; AH = last status byte 1, ZF if 0
	JZ	FDC_WAIT_STATUS_ERR_DONE	; skip if AH = 0
	PUSH	SI
	MOV	SI, OFFSET FDC_ERR1_MAP
FDC_ERR_MAP_LOOP:
	LODS	BYTE PTR CS:[SI]			; fetch next error byte
	SHL	AH, 1					; CF if this status flag
	JA	FDC_ERR_MAP_LOOP			; loop if NC (not this flag)
	POP	SI					;  and NZ (more flags to check)
FDC_WAIT_STATUS_ERR_DONE:
	MOV	AH, AL				; AH = last result
FDC_WAIT_ERR_EXIT:
	OR	_FD_LAST_OP, AH			; BDA 40:41H
	STC
FDC_WAIT_ERR_EXIT_OK:
	RET

;----------------------------------------------------------------------------;
; FDC Status register to INT 13h error map
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
	LDS	BX, IVT_1E				; DS:BX = INT 1EH in IVT
	XLAT 						; AL = byte
	POP	BX
	POP	DS
			ASSUME DS:NOTHING
	RET
INT_1E_PARAM ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	INT_0E

;----------------------------------------------------------------------------;
; INT 0EH - Floppy Disk Interrupt IRQ6
;----------------------------------------------------------------------------;
; This interrupt is issued upon floppy disk I/O completion and sets the
; floppy disk working interrupt flag at 40:3E, bit 7.
;----------------------------------------------------------------------------;
		ORG 0EF57H
INT_0E PROC
	STI						; necessary?
	PUSH	AX
	PUSH	DS
	XOR	AX, AX				; DS = BDA_ABS segment
	MOV	DS, AX
			ASSUME DS:_BDA_ABS
	OR	FD_CAL_ST_ABS, MASK FWIF	; turn on working interrupt flag
	MOV	AL, EOI 				; End of Interrupt OCW
	OUT	INT_P0, AL				; write EOI to port 0
	POP	DS
			ASSUME DS:NOTHING
	POP	AX
	IRET
INT_0E ENDP

;----------------------------------------------------------------------------;
; FDC_WAIT_INT: Wait for BDA Working Interrupt Flag from FDC
;----------------------------------------------------------------------------;
; Input: DS = BDA, DI = FD_LAST_OP
; Output: CF if timeout
;----------------------------------------------------------------------------;
FDC_WAIT_INT PROC
			ASSUME DS:_BDA
	STI						; ensure interrupts are on
	PUSH	AX 					; call preserve regs
	PUSH	CX
	MOV	CX, 2 * (1000/55) + 1		; timeout ~2 sec (37 ticks)
FDC_WAIT_INT_LOOP1:
	MOV	AX, TIMER.LW			; AX = time ticks
FDC_WAIT_INT_LOOP2:
	TEST	_FD_CAL_ST, MASK FWIF 		; check for WIF in FD_CAL_ST (3EH)
	JNZ	FDC_WAIT_INT_OK			; if so, exit
			IF FDC_HLT_WAIT GT 0
	HLT						; wait for any INT
			ELSE
	NOP						; allow extra time for INTs
			ENDIF
	CMP	AX, TIMER.LW			; has timer tick changed?
	JZ	FDC_WAIT_INT_LOOP2		; if not, wait for next INT
	LOOP	FDC_WAIT_INT_LOOP1		; decrement tick counter and resume loop
	OR	_FD_LAST_OP, FDC_ST_TIMEOUT 	; FDC result set time out, drive not ready
	STC
	JMP	SHORT FDC_WAIT_INT_DONE
FDC_WAIT_INT_OK:
	AND	_FD_CAL_ST, NOT MASK FWIF 	; clear working interrupt flag
FDC_WAIT_INT_DONE:
	POP	CX
	POP	AX
	RET
FDC_WAIT_INT ENDP

INT_13 ENDP

			IF POST_TEST_SEEK EQ 1
;----------------------------------------------------------------------------;
; FDC_RECAL_SEEK_TEST: Reset, Recalibrate and Seek test a floppy drive at POST
;----------------------------------------------------------------------------;
; Input:
;	DL = drive # to test (0 = A:, 1 = B:, etc) (bounds not checked)
;	DI = OFFSET FD_LAST_OP
; Output:
;	CF if error
; Clobbers: DI, SI, AX, BX (if FDC_ADV_SEEK)
;
; Size: 36 bytes
;----------------------------------------------------------------------------;
FDC_RECAL_SEEK_TEST PROC
	PUSH	CX
	CALL	FDC_RECAL				; Motor on, recal, DL = drive
	JC	FDC_TEST_DRIVE_EXIT		; exit if error
	JWB	FDC_TEST_DRIVE_DONE		; skip seek tests on warm boot
	IO_DELAY					; short pause before seek, CX=0
	MOV	SI, OFFSET FDC_SEEK_TRACKS
FDC_TEST_DRIVE_SEEK:
	LODS	BYTE PTR CS:[SI]			; next track to seek
	MOV	CH, AL				; CH = track
	CALL	FDC_SEEK				; CH = track, DL = drive
	JCXZ	FDC_TEST_DRIVE_DONE		; exit if track = 0
	JNC	FDC_TEST_DRIVE_SEEK		; loop unless error
FDC_TEST_DRIVE_DONE:
			IF IS_TURBO
	MOV	CH, 80H				; longer delay for faster PCs
			ELSE
	MOV	CH, 40H
			ENDIF
	IO_DELAY					; delay between drives
FDC_TEST_DRIVE_EXIT:
	POP	CX
	RET

;----------------------------------------------------------------------------;
; Track pattern for POST seek test
;
FDC_SEEK_TRACKS	DB	38, 2, 19, 0	; tracks (0 is end)

FDC_RECAL_SEEK_TEST ENDP
			ENDIF

;
; 20 BYTES HERE
;
BYTES_HERE	INT_1E

;----------------------------------------------------------------------------;
; INT 1E - Disk Initialization Parameter Table Vector
;----------------------------------------------------------------------------;
; Provides a "pluggable" method to allow additional disk ROMs or DOS to 
; replace this table.
;
;  00  Head Step Rate (SRT) = 0CH = 12ms
;      Head Unload Time (HUT) = 15 x (16ms increments) = 240ms(?)
;  01  Head Load Time = 2 (2ms increments) = 1, DMA flag (0 = use DMA)
;  02  timer ticks to wait before disk motor shutoff = 37
;  03  512 bytes per sector (0=128, 1=256, 2=512, 3=1024) = 2
;  04  sectors per track (last sector number) = 8
;  05  inter-block gap length/gap between sectors (mills) 42
;  06  data length, if sector length not specified = 0FFH
;  07  gap length between sectors for format (mills) 80
;  08  fill byte for formatted sectors = 0F6H
;  09  head settle time in milliseconds = 25
;  0A  motor startup time in eighths of a second = 4
;  MFM = 2
;
; https://stanislavs.org/helppc/dbt.html
; https://stanislavs.org/helppc/765.html
; https://stanislavs.org/helppc/int_1e.html
;----------------------------------------------------------------------------;
		ORG 	0EFC7H
INT_1E	DBT 	<DNB <12, 15>, 0010B, 37, 2, 8, 42, 0FFH, 80, 0F6H, 25, 4>

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
;----------------------------------------------------------------------------;
		ORG 0EFD2H
INT_17 PROC
		ASSUME DS:_BDA
	STI 						; enable interrupts
	CMP	DX, LENGTH LPT_ADDR		; is port number valid?
	JAE	INT_17_IRET 			; if not, exit
	PUSHX	DX, DI, CX, AX, DS		; call-preserve working regs
	MOV	CX, SEG _BDA 			; CH = 0, CL = 40H
	MOV	DS, CX				; DS = BDA
	MOV	DI, DX 				; DI = LPT port index (0-2)
	MOV	CL, LPT_TIME_B[DI]		; CX = port timeout
	SHL	DI, 1 				; convert to word-aligned index
	MOV	DX, LPT_ADDR_B[DI]		; DX = data port address
	POP	DS 					; restore DS
	TEST	DX, DX 				; is port index valid (detected)?
	JZ	INT_17_DONE 			; if not, exit
	DEC	AH
	JZ	INT_17_1				; AH = 1 then init
	JG	INT_17_2	 			; AH = 2 then status
							; AH = 0 fall through to print

;----------------------------------------------------------------------------;
; AH = 0 - Print Character
;----------------------------------------------------------------------------;
; Write character and returns status
;
; Input:
;	AH = -1 (not 0)
;	AL = character to print
;	CX = timeout "value" (the number of 64k loops)
;	DX = LPT data port (278, 378, 3BC)
;
; Output:
;	AH = printer status, see AH = 2
;
;----------------------------------------------------------------------------;
; 765	    |			- LCX		unused
;    4    |			- LCIRQ	0 = IRQ disable, 1=IRQ enable for ACK
;     3   |			- LCDR	1 = printer reads output,  (pin 17)
;      2  |			- LCINI	0 = initialize printer,  (pin 16)
;       1 |			- LCLF	1 = auto line feed,  (pin 14)
;        0|			- LCOUT	1 = output data to printer,  (pin 1)
; PRN_CTRL RECORD	LCX:3,LCIRQ:1,LCDR:1,LCINI:1,LCLF:1,LCOUT:1
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
	MOV	AL, MASK LCDR OR MASK LCINI OR MASK LCOUT ; /strobe pin HIGH
	INC	DX 				; DX = control port
	PUSH	DX				; I/O delay
	OUT	DX, AL
	POP	DX				; I/O delay
	MOV	AL, MASK LCDR OR MASK LCINI	; /strobe pin LOW
	OUT	DX, AL
	DEC	DX 				; reset to data port
	DEC	DX				; and fall through to status

;----------------------------------------------------------------------------;
; AH = 2 - Read printer port status
;----------------------------------------------------------------------------;
; Return status of specified printer port
;
; Input:
;	AH = 1 (not 2)
;	DX = LPT data port (278, 378, 3BC)
;
; Output:
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
	AND	AL, NOT (MASK LPX OR MASK LPTO)	; mask time-out pins
INT_17_2_STATUS_2:
	XOR	AL, MASK LPACK OR MASK LPIO ; acknowledge and error are active low
	MOV	CH, AL			; save status to CH so AL can be restored
INT_17_DONE:
	POP	AX				; restore AL
	MOV	AH, CH			; AH = status
	POP	CX
	POP	DI
	POP	DX
INT_17_IRET:
	IRET

;----------------------------------------------------------------------------;
; AH = 1 - Initialize printer port
;----------------------------------------------------------------------------;
; Input:
;	AH = 0 (not 1)
;	DX = LPT data port (278, 378, 3BC)
;
; Output:
;	AH = status, see AH = 2
;----------------------------------------------------------------------------;
INT_17_1:
	MOV	AL, MASK LCDR		; printer reads output = 1
	INC	DX
	INC	DX				; DX = control port
	OUT	DX, AL			; send to control port
	MOV	CH, HIGH 800H		; delay 800H-ish loops
	IO_DELAY 				; wait, then CX = 0
	OR	AL, MASK LCINI		; initialize printer = 1
	OUT	DX, AL			; send to control port
	DEC	DX				; DX = status port
	JMP	SHORT INT_17_2_STATUS	; small delay, read status and return
INT_17 ENDP

CRLF_SHOW_CURSOR PROC
;----------------------------------------------------------------------------;
; CRLF then show cursor display (this exists to utilize the free bytes here)
;----------------------------------------------------------------------------;
	CALL	CRLF

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
	JMP	SHORT SET_CURSOR

;----------------------------------------------------------------------------;
; Hide cursor display
;----------------------------------------------------------------------------;
; Clobbers CX
;----------------------------------------------------------------------------;
HIDE_CURSOR PROC
	MOV	CX, DBW < 00100000b >	; hide cursor (CH bit 5 = 1)

;----------------------------------------------------------------------------;
; Set Video Cursor type
;----------------------------------------------------------------------------;
; Input:
;	CX = cursor type
;----------------------------------------------------------------------------;
SET_CURSOR PROC
	PUSH	AX				; (not necessary)
	MOV	AH, 1
	INT	10H
	POP	AX
	RET
SET_CURSOR ENDP

HIDE_CURSOR ENDP
SHOW_CURSOR ENDP
CRLF_SHOW_CURSOR ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	INT_10_JMP

;----------------------------------------------------------------------------;
; INT 10h - Function Jump Table
;----------------------------------------------------------------------------;
		ORG 0F045H
INT_10_JMP LABEL WORD
	DW	OFFSET INT_10_0		; AH = 0 - Set video mode
	DW	OFFSET INT_10_1		; AH = 1 - Set cursor type
	DW	OFFSET INT_10_2		; AH = 2 - Set cursor position
	DW	OFFSET INT_10_3		; AH = 3 - Read cursor position
			IF LIGHT_PEN EQ 1
	DW	OFFSET INT_10_4		; AH = 4 - Read light pen
			ELSE
	DW	OFFSET INT_10_RET		; AH = 4 - Read light pen (not supported)
			ENDIF
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
L_INT_10_JMP	EQU	($-INT_10_JMP)/2

;----------------------------------------------------------------------------;
; INT 10h - Video BIOS Services
;----------------------------------------------------------------------------;
; BIOS Interface to CGA/MDA display adapters.
;----------------------------------------------------------------------------;
; References and Info Sources:
;  "PC System Programming", Tischer
;  "Programmer's Guide to PC Video Systems", Second Edition, Wilton
;  https://github.com/joncampbell123/dosbox-x/blob/master/src/ints/int10_char.cpp
;  https://github.com/joncampbell123/dosbox-x/issues/256
;  https://www.seasip.info/VintagePC/cga.html
;  https://www.reenigne.org/blog/crtc-emulation-for-mess/
;  (many other posts and articles...)
;
; Thx to @Raffzahn for "clean room" specs for various display routines.
;----------------------------------------------------------------------------;
		ORG 0F065H
INT_10 PROC
	STI					; enable interrupts
	CMP	AH, L_INT_10_JMP-1	; function valid?
	JA	INT_10_IRET			; exit if function not valid
	PUSHX	ES, DS, DI			; always preserve these registers
	CLD					; string instructions forward direction
	MOV	DI, SEG _BDA		; DS = BDA segment
	MOV	DS, DI
	MOV	DI, AX			; save AX
	XCHG	AH, AL			; AL = function, AH = video mode
	SHL	AL, 1				; word align index
	CBW					; AX = jump index
	XCHG	AX, DI			; restore AX, DI = jump offset
	CALL	CS:INT_10_JMP[DI]
INT_10_DONE:
	POPX	DI, DS, ES
INT_10_IRET:
	IRET

;----------------------------------------------------------------------------;
; Is Current video mode text or GFX?
;----------------------------------------------------------------------------;
; Input:
; 	DS = BDA (040h)
; Output:
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
	TEST	AL, 4 AND 5 AND 6		; NZ if GFX modes 4,5,6?
INT_10_IS_TXT_DONE:
	RET
INT_10_IS_TXT ENDP

;----------------------------------------------------------------------------;
; Is Current video CGA 80 col?
;----------------------------------------------------------------------------;
; Output:
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
INT_1D_40		CRTC	<38H,28H,2DH,0AH,1FH,06H,19H,1CH,02H,07H,06H,07H>
O_INT_1D_40		EQU	INT_1D_40-INT_1D		; 40x25 mode data offset

; 80x25 CGA text
		IF ARCH_TYPE EQ ARCH_CPQ
INT_1D_80		CRTC	<71H,50H,5AH,0AH,19H,06H,19H,19H,02H,0DH,0BH,0CH>
		ELSE
INT_1D_80		CRTC	<71H,50H,5AH,0AH,1FH,06H,19H,1CH,02H,07H,06H,07H>
		ENDIF
O_INT_1D_80		EQU	INT_1D_80-INT_1D		; 80x25 mode data offset

; 320x200 CGA graphics
INT_1D_GFX		CRTC	<38H,28H,2DH,0AH,7FH,06H,64H,70H,02H,01H,06H,07H>
O_INT_1D_GFX	EQU	INT_1D_GFX-INT_1D		; 320x200 mode data offset

; MDA text
INT_1D_MDA		CRTC	<61H,50H,52H,0FH,19H,06H,19H,19H,02H,0DH,0BH,0CH>
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
;
; Clobbers: ES
;----------------------------------------------------------------------------;
; Things you must do:
; 	1. Check that the new video mode is valid: 0-7. For MDA, the mode
;		will always be 7. If CGA mode > 6, reset in current mode.
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
			IF CPU_TYPE	EQ CPU_V20
	PUSHA						; preserve all registers
			ELSE
	PUSHX	BX, DX, BP, CX, SI
			ENDIF
	MOV	DI, OFFSET VID_MODE		; start with VID_MODE (49H)
	CMP	AL, 7					; is new video mode > 7?
	JB	INT_10_0_1				; if not, is valid mode
	MOV	AL, [DI]				; otherwise use current mode
INT_10_0_1:
	XCHG	AX, BX				; BL = new video mode

;----------------------------------------------------------------------------;
; Clear all video data in BDA
;
	XOR	AX, AX
	MOV	CX, L_VID_BDA / 2			; Video data in BDA (in WORDs)
	PUSH	DS
	POP	ES					; ES = BDA
	REP	STOSW					; clear data, set CX = 0

;----------------------------------------------------------------------------;
; Determine video adapter type and new mode and re-program 6845
;
	CMP_EFLAG VID, VID_MDA			; is switch MDA (ON, ON)?
	MOV	AL, CL				; 0 = CGA disable video signal
	MOV	SI, O_INT_1D_80			; SI = CGA 80 CRTD offset (10H)
	MOV	BH, VID_DEF_COLS			; default 80 columns
	MOV	CH, HIGH SIZE MDA_MEM		; Total MDA video memory = 1000H (4K)
	MOV	AH, CH				; MDA/CGA 80x25 page size = 1000H (4K)
	MOV	DX, MDA_CTRL			; MDA Mode Select Register (03B8H)
	MOV	DI, DBW <VID_ATTR<>, VID_SP>	; fill memory with attr and space
	JNE	INT_10_0_IS_CGA			; jump if not MDA

;----------------------------------------------------------------------------;
; Is MDA (mode 7)
;
	INC	AX					; 1 = MDA disable video signal value
	MOV	BP, SEG _MDA_MEM			; BP = MDA memory segment (0B000H)
	MOV	BL, 7					; only valid MDA display mode is 7
	MOV	SI, O_INT_1D_MDA			; SI = MDA CRTD offset (30H)
	JMP	SHORT INT_10_0_DETECT_DONE	; MDA mode selected, continue

;----------------------------------------------------------------------------;
; Is CGA (modes 0-6)
;
INT_10_0_IS_CGA:
	MOV	CH, HIGH CGA_MEM_SZ		; Total CGA video memory = 4000H (16K)
	MOV	DL, LOW CGA_CTRL			; CGA Mode Select Register (03D8H)
	MOV	BP, SEG _CGA_MEM			; BP = CGA memory segment (0B800H)
	TEST	BL, 0100B				; text or gfx mode?
	JZ	INT_10_0_IS_CGA_TEXT		; jump if text

;----------------------------------------------------------------------------;
; Is CGA graphics (modes 4-6)
;
	SHL	SI, 1					; SI = CGA GFX CRTD offset (20H)
	MOV	AH, HIGH CGA_MEM_SZ		; CGA gfx page size = 4000H (16K)
	XOR	DI, DI				; DI = memory fill 0's
	TEST	BL, 0010B				; is 80 or 40 col text?
	JNZ	INT_10_0_DETECT_DONE		; jump if 80
	JMP	SHORT INT_10_0_IS_40_COL	; else set 40 columns

;----------------------------------------------------------------------------;
; Is CGA text (modes 0-3)
;
INT_10_0_IS_CGA_TEXT:
	TEST	BL, 0010B				; is 80 or 40 col text?
	JNZ	INT_10_0_DETECT_DONE		; jump if 80

;----------------------------------------------------------------------------;
; Is CGA 40 col text (modes 0-1)
;
	MOV	AH, HIGH SIZE CGA_MEM_40	; CGA 40x25 page size = 800H (2K)
	XOR	SI, SI				; SI = CGA 40 CRTD offset (00H)

;----------------------------------------------------------------------------;
; Is CGA 40 col text/gfx (modes 0-1, 4-5)
;
INT_10_0_IS_40_COL:
	SHR	BH, 1					; BH = 40 columns

INT_10_0_DETECT_DONE:
	MOV	WORD PTR VID_MODE, BX		; write BDA video mode and columns
	MOV	ES, BP				; ES = video memory segment
	MOV	VID_MEM_SEG, BP			; write video segment for later
	OUT	DX, AL				; disable video
	MOV	BYTE PTR VID_BUF_SZ[1], AH	; write BDA video page size
	SUB	DX, CGA_CTRL-CGA_IDX		; DX = 6845 index register port
	MOV	VID_PORT, DX			; write BDA video I/O port
	MOV	BP, BX				; save video mode to BP

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
	MOV	AX, CX				; AX = 0
	MOV	VID_PAGE, AL			; video page 1 = 0
	MOV	DS, AX				; DS = IVT
			ASSUME DS:_IVT
	LDS	BX, IVT_1D				; DS:BX = BIOS:INT_1D
			ASSUME DS:NOTHING
	MOV	DI, WORD PTR [BX][SI].CSL	; DI = cursor type (start and end)
	MOV	CL, SIZE CRTC			; size of CRTC data
INT_10_0_CRTC_LOOP:
	MOV	AH, [BX][SI]			; AH = next byte from table
	OUT	DX, AX				; write AH to register index AL
	INC	AX					; next register index
	INC	SI					; next byte in table
	LOOP	INT_10_0_CRTC_LOOP
	POP	DS					; DS = BDA
			ASSUME DS:_BDA

;----------------------------------------------------------------------------;
; Send mode and color bytes to display adapter
;
	XCHG	AX, BP				; AL = new video mode
	CMP	AL, 6					; is CGA color gfx mode?
	MOV	AH, VID_CSGFX <>			; use for 640x200 mode 6
	JE	INT_10_0_COLOR_BYTE		; jump if so
	MOV	AH, VID_CSTXT <>			; otherwise use for text/low gfx
INT_10_0_COLOR_BYTE:
	MOV	BX, OFFSET CRT_MODE
	XLAT	CS:[BX]				; AL = control byte data
	ADD	DX, CGA_CTRL-CGA_IDX		; DX = control reg port (3D8H)
	MOV	WORD PTR VID_MODE_REG, AX	; write mode and color to BDA
	OUT	DX, AX				; write mode and color to adapter
	XCHG	AX, DI				; AX = cursor bytes from CRTC table
	XCHG	AH, AL				; convert endian for cursor bytes
	MOV	VID_CURS_TYPE, AX			; write cursor type to BDA
			IF CPU_TYPE	EQ CPU_V20
	POPA						; restore all registers
			ELSE
	POPX	SI, CX, BP, DX, BX
			ENDIF
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
	MOV	AL, CRTC.CSL		; AL = cursor start index (scan line)
	MOV	AH, CH			; CH = cursor starting scan line (top)
	MOV	DX, VID_PORT		; DX = 6845 index register port
	OUT	DX, AX			; write AH to 6845 reg index in AL
	INC	AX				; AL = cursor end index (scan line)
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
	JNE	INT_10_2_DONE		; if not, do nothing and exit
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
	MOV	AL, CRTC.CA_H		; 6845 Cursor address high reg (0EH)
	MOV	AH, BH			; Cursor address (MSB)
	MOV	DX, VID_PORT
	OUT	DX, AX			; write AH to index AL
	INC	AX				; AL = CA_L (0FH)
	MOV	AH, BL			; Cursor address (LSB)
	OUT	DX, AX			; write AH to index AL
	POP	DX
	POP	BX
INT_10_2_DONE:
	POP	AX
	RET
INT_10_2 ENDP

;----------------------------------------------------------------------------;
; INT 10,3 - Read cursor position and Size for current page
;----------------------------------------------------------------------------;
; Output:
;	ZF = 0 and BH = 0 if MDA/CGA GFX
;  	ZF = 1 and BH = VID_PAGE if CGA text
;----------------------------------------------------------------------------;
INT_10_3_CUR_PAGE PROC
	XOR	BH, BH			; BH = 0
	TEST	VID_MODE, 0100B		; is >= 4?
	JNZ	INT_10_3			; jump if not MDA or GFX
	MOV	BH, VID_PAGE		; otherwise BH = VID_PAGE

;----------------------------------------------------------------------------;
; INT 10,3 - Read cursor position and Size
;----------------------------------------------------------------------------;
; Input:
;	AH = 03
;	BH = video page
; Output:
;	CH = cursor starting scan line (low order 5 bits)
;	CL = cursor ending scan line (low order 5 bits)
;	DH = row
;	DL = column
;----------------------------------------------------------------------------;
INT_10_3 PROC
	XCHG	AX, DX			; save AX
	MOV	AL, BH			; AL = video page
	CBW					; AX = video page
	XCHG	AX, DI			; DI = video page
	SHL	DI, 1				; word align index
	XCHG	AX, DX			; restore AX
	MOV	DX, VID_CURS_POS[DI]
	MOV	CX, VID_CURS_TYPE
	RET
INT_10_3 ENDP
INT_10_3_CUR_PAGE ENDP

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
	PUSHX	AX, BX, DX			; call-preserve working registers

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
	MOV	AL, CRTC.SA_H		; 6845 Start address register
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
; it will scroll incorrectly. This behavior has been preserved.
;----------------------------------------------------------------------------;
INT_10_7 PROC
	STD					; Set direction flag

;----------------------------------------------------------------------------;
; INT 10,6 - Scroll active page up
;----------------------------------------------------------------------------;
; Input: same as INT 10,7 above
;----------------------------------------------------------------------------;
INT_10_6 PROC
	PUSHX	AX, BX, SI			; call-preserve these registers
	LES	SI, VID_MEM_SEG_DW	; ES = video/regen RAM segment (B800 or B000)
	PUSH	BP

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
	XCHG	AX, SI			; SI = memory offset

;----------------------------------------------------------------------------;
; Is graphics mode?
;
	CALL	INT_10_IS_TXT		; NZ if CGA GFX, ZR if CGA/MDA Text
	MOV	DH, 0				; DX = lower right column position
	PUSH	DS				; save BDA data SEG
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
	ADD	DX, SI			; DX = byte offset of new bottom row and col
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
	INC	DX				; convert 0-based indexes to 1-based loop counters
	INC	DH
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

INT_10_CGA_CHECK:
				IF CGA_SNOW_REMOVE GT 0
;----------------------------------------------------------------------------;
; If CGA, blank video during memory writes to avoid "CGA snow" effect
;
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
				ENDIF

INT_10_6_CHECK_CLS:
	TEST	AL, AL			; is number of lines to scroll 0?
	JZ	INT_10_6_TXT_CLR		; if so, skip move and only clear

;----------------------------------------------------------------------------;
; Move scrolled window rectangle to new location in video memory 
;
	SUB	DH, AL			; DH = rect height - lines to scroll
	JZ	INT_10_6_TXT_CLR_1	; is number of lines to move 0?
	ADD	SI, BP			; SI = source row starting address
INT_10_6_TXT_MOVE_LOOP:
	MOV	CL, DL			; CX = number of columns (chars) to move
	REP	MOVSW				; copy row from [DS:SI] to [ES:DI]
	ADD	DI, BX			; move to start of next row
	ADD	SI, BX
	DEC	DH
	JNZ	INT_10_6_TXT_MOVE_LOOP	; loop through all rows
INT_10_6_TXT_CLR_1:
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
				IF CGA_SNOW_REMOVE GT 0
	POPF					; ZF if CGA/80, NZ if not
				ENDIF
	POP	DS				; restore BDA SEG

				IF CGA_SNOW_REMOVE GT 0
	JNZ	INT_10_6_DONE		; jump if not CGA/80
;----------------------------------------------------------------------------;
; If is CGA 80 column, re-enable the video signal
;
INT_10_6_ENABLE_CGA:
	MOV	AL, VID_MODE_REG		; reload the current control register
	MOV	DX, CGA_CTRL
	OUT	DX, AL			; write to CGA Control Register
				ENDIF

INT_10_6_DONE:
	POPX	BP, SI, BX, AX
	RET

;----------------------------------------------------------------------------;
; INT 10,6/7 - Scroll up or down in graphics mode
;----------------------------------------------------------------------------;
; Input:
;	SI = memory offset of col 0 of new bottom row
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
	SHL	SI, 1				; BYTE (char) align memory offset for line
	SHL	SI, 1				;  (default for 640x200)
	ADD	DX, SI
	XCHG	DX, DI			; DI = memory offset of new rect bottom
	INC	DX				; DX = original row/col
	INC	DH				; use 0-based indexes for 1-based counters
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
	;JZ	INT_10_SCR_GFX_CLR_1	; check that loop > 1 (necessary?)
	MOV	AX, SI			; save source
	MOV	BX, DI			; save destination
INT_10_SCR_GFX_MOVE_LOOP:
	MOV	CL, DL			; # of pixels to copy
	REP	MOVSB				; copy odd field
	MOV	SI, CGA_MEM_FLD		; vid mem offset for interlaced field
	LEA	DI, [BX][SI]		; add to line offset
	ADD	SI, AX
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
INT_10_SCR_GFX_CLR_1:
	MOV	DH, BL			; # of lines to clear
INT_10_SCR_GFX_CLR:
	MOV	AL, BH			; AL = attribute/color byte to write
	MOV	SI, DI			; save destination
INT_10_SCR_GFX_CLR_LOOP:
	MOV	CL, DL			; # of pixels to clear
	REP	STOSB				; clear odd field
	LEA	DI, CGA_MEM_FLD[SI]	; vid mem offset for interlaced field
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
; Output:
;	AH = attribute of character (alpha modes only)
;	AL = character at cursor position
;
; http://www.techhelpmanual.com/92-cga_video_snow_and_cls_flash.html
;----------------------------------------------------------------------------;
INT_10_8 PROC
	CALL	INT_10_GET_CUR_ADDR	; ES:DI = video RAM offset of cursor
	MOV	AL, VID_MODE		; AL = current video mode (0-7)
	CMP	AL, 7				; is MDA mode 7?
	JNZ	INT_10_8_CHK_CGA		; if not, jump to check CGA or gfx

;----------------------------------------------------------------------------;
; Standard, fast routine
;
INT_10_8_FAST:
	MOV	AX, ES:[DI]			; just read from memory and return
	RET

INT_10_8_CHK_CGA:
	SHR	AL, 1				; Video modes: 0=40,1=80,2=low-gfx,3=hi-gfx
	CMP	AL, 1				; is CGA modes 2,3?
			IF CGA_SNOW_REMOVE GT 0
	JNE	INT_10_8_NOT_CGA		; jump if not

;----------------------------------------------------------------------------;
; CGA snow-removal routine. Wait for a blanking interval before read.
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

	JBE	INT_10_8_FAST		; if not GFX modes 4,5,6 jump to fast text
						; fall through to graphics

;----------------------------------------------------------------------------;
; INT 10,8 - Read character and attribute at cursor in CGA graphic mode
;----------------------------------------------------------------------------;
; Input:
;	AL = 3 if high res, 2 if low-res
;	ES = video mem segment
; Output:
;	AH = 0
;	AL = character at cursor position, 0 if not found
;----------------------------------------------------------------------------;
INT_10_8_MODE_GFX PROC
	PUSHX	BX, CX, DX, SI
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
	MOV	DX, CGA_MEM_FLD		; CGA memory interlace field offset
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
	XOR	AX, AX			; start codepoint counter at 0
INT_10_8_GFX_SEARCH_TBL:
	MOV	BX, 128			; loop counter for each charset table
INT_10_8_GFX_SEARCH_CHR:
	PUSH	SI				; save target bitmap and ROM table offsets
	PUSH	DI
	MOV	CL, 4				; compare [CS:SI] (ROM table) to
	REPE	CMPSW				;  [ES:DI] (char bitmap from vid mem)
	POP	DI				; restart target bitmap at beginning 
	POP	SI				; ROM table always advanced by 8 
	JE	INT_10_8_GFX_DONE		; end search if match found
	ADD	SI, 8				; next char in table
	INC	AL				; next codepoint to try
	JZ	INT_10_8_GFX_DONE		; if AL > 255, char not found
	DEC	BX				; dec charset loop counter
	JNZ	INT_10_8_GFX_SEARCH_CHR	; loop until end of table set

;----------------------------------------------------------------------------;
; Search again in user charset at 0000:007C (INT 1Fh).
;
	CWD					; DX = 0000h
	MOV	DS, DX			; DS = IVT
			ASSUME DS:_IVT
	LDS	SI, IVT_1F			; DS:SI = user charset
			ASSUME DS:_BDA
	MOV	DX, DS			; see if custom table has been vectored
	OR	DX, SI			;  and not the default of 0000:0000
	JNZ	INT_10_8_GFX_SEARCH_TBL	; if so, continue search
	XOR	AX, AX			; otherwise return not found (0)
INT_10_8_GFX_DONE:
	ADD	SP, 8				; restore stack pointer
	POPX	SI, DX, CX, BX
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
	CALL	INT_10_GET_CUR_ADDR	; ES:DI = video RAM offset of cursor
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
	CMP	AL, 1				; is CGA modes 2,3?
			IF CGA_SNOW_REMOVE GT 0
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

	JBE	INT_10_9A_FAST		; is not GFX modes 4,5,6 jump to fast text
	POP	AX				; restore AX and fall through to graphics

;----------------------------------------------------------------------------;
; INT 10, 9 and A - Write character in CGA graphics mode
;----------------------------------------------------------------------------;
INT_10_9A_MODE_GFX PROC
	PUSHX	AX, BX, DX, SI, DS
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
	LDS	SI, IVT_1F			; use custom font table

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
	RCL	BX, 1				; shift CF into next bit
	SAHF					; restore CF
	RCL	BX, 1				; shift CF into next bit again
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
	XOR	DI, CGA_MEM_FLD		; alternate video fields
	TEST	DI, CGA_MEM_FLD		; is an even field next?
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
	POPX	DS, SI, DX, BX, AX

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
	XOR	AH, ES:CGA_MEM_FLD[DI]	; and even field

;----------------------------------------------------------------------------;
; Write next two bytes to each field
;
INT_10_9A_GFX_HIGH_WR:
	STOSB					; write odd field in AL
	MOV	ES:CGA_MEM_FLD[DI][-1], AH	; write even field in AH
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
			ASSUME DS:_BDA
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
;	|7|6|5|4|3|2|1|0|  3D9 Color Select Register (Graphics)
;	 | | | | | `-------- RGB for background
;	 | | | | `--------- intensity
;	 | | | `---------- unused
;	 | | `----------- 1 = palette 1, 0=palette 0 (see below)
;	 `-------------- unused
;	  Palette 0 = green, red, brown
;	  Palette 1 = cyan, magenta, white
;
; VID_CSGFX	RECORD	CGPH:2=11B,CGPL:1,CGX:1,CGIN:1,CGBG:3
;----------------------------------------------------------------------------;
INT_10_B PROC
	PUSH	AX
	MOV	AL, VID_COLOR			; get current color byte
	TEST	BH, BH				; set BG/border or palette?
	JNZ	INT_10_B_SET_PAL			; jump if set palette
INT_10_B_SET_COL:
	AND	AL, MASK CGPH OR MASK CGPL	; isolate current palette
	AND	BL, 00011111B			; isolate color bits
	JMP	SHORT INT_10_B_DONE
INT_10_B_SET_PAL:
	AND	AL, NOT MASK CGPL			; clear palette bit
	AND	BL, 00000001B			; isolate palette selector bit
			IF CPU_TYPE	EQ CPU_V20
	ROR	BL, 3					; move low bit into bit 5
			ELSE
		REPT	3
	ROR	BL, 1					; move low bit into bit 5
		ENDM
			ENDIF
INT_10_B_DONE:
	OR	AL, BL				; combine bytes
	MOV	VID_COLOR, AL			; save to BDA
	PUSH	DX
	MOV	DX, VID_PORT
	ADD	DX, CGA_COLOR-CGA_IDX		; DX = 6845 color select reg (3D9H)
	OUT	DX, AL				; send to CGA Color Select Register
	POP	DX
	POP	AX
	RET
INT_10_B ENDP

;----------------------------------------------------------------------------;
; INT 10,C - Write graphics pixel at coordinate
;----------------------------------------------------------------------------;
; Input:
;	AL = color value (XOR'ed with current pixel if bit 7=1)
;	BH = page number, see VIDEO PAGES
;	CX = column number (zero based)
;	DX = row number (zero based)
;----------------------------------------------------------------------------;
INT_10_C PROC
	PUSH	AX
	PUSH	CX
	CALL	INT_10_GFX_PIXEL		; ES:DI = memory offset, AH/CL mask/counter
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
; Output:
;	AL = color of pixel read
;	AH clobbered
;----------------------------------------------------------------------------;
INT_10_D PROC
	PUSH	CX
	CALL	INT_10_GFX_PIXEL		; ES:DI = memory offset, AH/CL mask/counter
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
; Output
;	DI = pixel byte offset
;	AH = pixel data mask
;	CL = pixel right shift counter
;	CH = pixel index (big endian)
;	ES = VID_MEM_SEG
;
; Example of read:
;	MOV	AL, PIXEL_DAT
;	SHR	AL, CL
;	AND	AL, AH
;
; http://www.techhelpmanual.com/89-video_memory_layouts.html
;----------------------------------------------------------------------------;
INT_10_GFX_PIXEL PROC
	LES	DI, VID_MEM_SEG_DW	; ES = video/regen RAM segment
	PUSH	BX
	PUSH	DX

;----------------------------------------------------------------------------;
; Calculate X offset
;
	MOV	DI, CX			; DI = X position (zero based)
	SHR	DI, 1
	SHR	DI, 1				; DI = DI / 4 (two bit alignment)

;----------------------------------------------------------------------------;
; Unpack pixel bit(s)
;
	MOV	AH, 0011B			; pixel mask = 0011B
	MOV	BL, AH			; index mask = 0011B (bits 0-3)
	MOV	CH, CL			; save CH = CL
	MOV	CL, 1				; ROL multiplier = 1
	CMP	VID_MODE, 6			; is 640x200 gfx mode?
	JB	NOT_HI_RES			; if low-res, skip

;----------------------------------------------------------------------------;
; Is "high res" (640x200)
;
	SHR	AH, 1				; pixel mask = 0001B
	RCL	BL, 1				; index mask = 0111B (bits 0-7)
	DEC	CX				; ROL multiplier = 0
	SHR	DI, 1				; DI = DI / 8 (one bit alignment)
NOT_HI_RES:

;----------------------------------------------------------------------------;
; Calculate right-shift counter:
; - 640x200: CL = (7 - i) * 1
; - 320x200: CL = (3 - i) * 2
;
	AND	CH, BL			; CH = packed pixel index
	SUB	BL, CH			; calculate right-shift counter
	SHL	BL, CL			; multiply by 1 (high res) or 2 (low res)
	MOV	CL, BL			; CL = shift count

;----------------------------------------------------------------------------;
; Calculate Y offset
;
; Y offset = (DX / 2) * 80 + 2000H[DX is odd]
;
	SHR	DX, 1				; DX = DX / 2
	XCHG	DL, DH			; DX = DX << 8
	JNC	FIELD_EVEN			; is odd or even field?
	ADD	DI, CGA_MEM_FLD		; odd field address offset
FIELD_EVEN:
	SHR	DX, 1
	SHR	DX, 1
	ADD	DI, DX			; DI += (DX / 2) * 16
	SHR	DX, 1
	SHR	DX, 1
	ADD	DI, DX			; DI += (DX / 2) * 64
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
;		- LF: increment row and go to step 5 to check if scroll is needed
;	4. Write the char to the current position (INT 10,A)
;	5. If new row > last row, scroll up 1 row (INT 10,8).
;	6. Update cursor position (INT 10,6)
;
;----------------------------------------------------------------------------;
INT_10_E PROC
	PUSHX	AX, BX, CX, DX
	CALL	INT_10_3_CUR_PAGE		; Get cursor pos: DH = row, DL = column
	CMP	AL, CR			; is maybe a control code?
	JBE	INT_10_E_CTRL		; if so, jump to handle it

;----------------------------------------------------------------------------;
; Handle a regular char
;
INT_10_E_CHAR:
	MOV	CX, 1				; repeat only once
	CALL	INT_10_A			; write char in AL at current row/col

;----------------------------------------------------------------------------;
; Handle line wrap
;
	MOV	AL, BYTE PTR VID_COLS	; get screen cols (80 or 40)
	DEC	AX				; fix 0 index (79 or 39)
	CMP	DL, AL			; reached end of screen cols?
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
	DEC	DH				; undo row scroll
	CALL	INT_10_IS_TXT		; ZF = 1 if CGA/MDA Text, ZF = 0 if gfx
	CBW					; if gfx mode, attribute AH = 0
	JNZ	INT_10_E_SCROLL_UP	; jump if graphics
	CALL	INT_10_8			; Read character: AH = attribute, AL = char

;----------------------------------------------------------------------------;
; Scroll up one line
;
INT_10_E_SCROLL_UP:
	PUSH	BX				; save video page (BH)
	XCHG	AX, BX			; BH = attribute
	MOV	AX, DBW <6, 1>		; AH = 06H Scroll Window Up, AL = 1 line
	XOR	CX, CX			; scroll top left: CH = row 0, CL = col 0
	PUSH	DX				; save cursor bottom
	MOV	DL, BYTE PTR VID_COLS	; DL = right-most column (1-indexed)
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
	POPX	DX, CX, BX, AX		; restore caller registers
	RET

;----------------------------------------------------------------------------;
; Handle control codes
;
INT_10_E_CTRL:
	JE	INT_10_E_CR			; is a CR? (from above)
	CMP	AL, LF			; is an LF?
	JE	INT_10_E_LF
	CMP	AL, BS			; is a backspace?
	JE	INT_10_E_BS
	CMP	AL, BELL			; Isabelle?
	JNE	INT_10_E_CHAR		; otherwise, handle as a normal char
INT_10_E_BELL:
	CALL	BEEP				; beep for ^G
	JMP	INT_10_E_DONE		; exit
INT_10_E_CR:
	XOR	DL, DL			; move to column 0
	JMP	INT_10_E_CURS		; update cursor
INT_10_E_LF:
	INC	DH				; move to next row
	JMP	INT_10_E_SCROLL		; maybe scroll
INT_10_E_BS:
	DEC	DL				; back space one column
	JS	INT_10_E_DONE		; if first column, do nothing and exit
	JMP	INT_10_E_CURS		; update cursor

INT_10_E ENDP

;----------------------------------------------------------------------------;
; INT 10,F - Get current video state
;----------------------------------------------------------------------------;
; Input:
;	AH = 0F
; Output
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
; Output:
;	DI = memory offset of current cursor in memory
;	ES = video RAM segment
; Clobbers: AX
;----------------------------------------------------------------------------;
INT_10_GET_CUR_ADDR PROC
	PUSH	DX
	MOV	AL, BH			; AL = display page
	LES	DI, VID_MEM_SEG_DW	; ES = video RAM segment
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
	RET
INT_10_GET_CUR_ADDR ENDP

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
;	|7|6|5|4|3|2|1|0|  3B8H CRT Control Port
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

;----------------------------------------------------------------------------;
; Display system hardware config
;----------------------------------------------------------------------------;
; Input:
;	DS = BDA (0040)
;
; Clobbers: AX, BX, CX, SI
; Size: 193 bytes
;----------------------------------------------------------------------------;
POST_SYS_CONFIG PROC
			ASSUME DS:_BDA

			IF POST_VIDEO_TYPE EQ 1
;----------------------------------------------------------------------------;
; Display Video Type
;----------------------------------------------------------------------------;
POST_SYS_VIDEO PROC
	POST_COL_2	POST_VIDEO, POST_CLR_VAL1 ; display "Video" left column
							; default to "None"

;----------------------------------------------------------------------------;
; Check if INT 10 is using this BIOS. If so, must be CGA or MDA.
;
	PUSH	DS
	XOR	AX, AX				; AX = SEG _IVT
	MOV	DS, AX				; set IVT segment for LDS
			ASSUME DS:_IVT
	LDS	AX, DWORD PTR IVT_10		; if BIOS, DS = 0F000H, AX = 0F065H
	CMP	AX, OFFSET INT_10			; is offset the BIOS IRR for INT 10?
	MOV	AX, DS				; save for next compare
	POP	DS					; restore DS
			ASSUME DS:_BDA
	JNE	CHECK_VGA				; if not, jump to VGA check
	MOV	BX, CS				; AX = BIOS code segment
	CMP	AX, BX				; is BIOS segment?
	JNE	CHECK_VGA				; if not, jump to VGA check

;----------------------------------------------------------------------------;
; Read BDA for video type
;
BIOS_VIDEO:
	CALL	INT_10_IS_TXT			; CF = 1 if MDA mode 7
	MOV	SI, OFFSET POST_MDA		; default "MDA"
	JC	POST_SYS_VIDEO_DONE
	MOV	SI, OFFSET POST_CGA		; otherwise "CGA"
	JMP	SHORT POST_SYS_VIDEO_DONE

;----------------------------------------------------------------------------;
; Check if VGA
; stanislavs.org/helppc/int_10-1a.html
;
CHECK_VGA:
	MOV	AX, DBW <1AH, 0>			; AH = 1AH, get video display
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
	MOV 	AH, 12H				; AH = 12H, get video configuration
	MOV	BL, 10H				; configuration info
	INT	10H
	CMP	BL, 10H				; check if param hasn't changed
	JE	POST_SYS_VIDEO_DONE		; jump if not EGA
	MOV	SI, OFFSET POST_EGA		; is "EGA"

POST_SYS_VIDEO_DONE:
	CALL	OUT_SZ				; display detected video adapter
	CALL	POST_END_COL_NL			; end of column with NL and RET

POST_SYS_VIDEO ENDP
			ELSE
	CALL	CRLF					; clear row if video type not shown
			ENDIF

;----------------------------------------------------------------------------;
; Display CPU type
;
	POST_COL_1	POST_CPU, POST_CLR_VAL1	; display 'CPU' left column
							;  SI now points to '8088'
CPU_CHECK_TYPE_2:
	TEST_GFLAG  V20				; ZF = 0 if V20, ZF = 1 if 8088
	JZ	CPU_CHECK_TYPE_2_DONE		; jump if 8088
	MOV	SI, OFFSET POST_V20		; if not, is V20
CPU_CHECK_TYPE_2_DONE:
	CALL	OUT_SZ				; write CPU type
	POST_COL_END				; end first column

;----------------------------------------------------------------------------;
; Display FPU/math co-processor
;
FPU_CHECK:
	POST_COL_2  POST_FPU, POST_CLR_VAL1	; display 'FPU', SI now '8087'
	TEST_EFLAG  FPU				; was FPU detected?
	JNZ	FPU_DISP_DONE			; jump to output if FPU
	MOV	SI, OFFSET POST_NONE		; otherwise 'None'
FPU_DISP_DONE:
	CALL	OUT_SZ				; display string
	POST_COL_END_NL				; end second column, move to NL

;----------------------------------------------------------------------------;
; Display LPT ports
;
	POST_COL_1	POST_LPT, POST_CLR_VAL2	; display 'LPT' in column 1
	GET_EFLAG   LPT				; AX = number of LPT ports
	XCHG	AX, CX				; CX = number of ports
	MOV	SI, OFFSET LPT_ADDR
	CALL	SHOW_PORT_COUNT

;----------------------------------------------------------------------------;
; Display COM ports
;
	POST_COL_2	POST_COM, POST_CLR_VAL2	; display 'COM' in column 2
	GET_EFLAG   COM				; AX = number of COM ports
	XCHG	AX, CX				; CX = number of ports
	XOR	SI, SI				; OFFSET COM_ADDR = 0000H

;----------------------------------------------------------------------------;
; Display I/O addresses of COM or LPT ports on POST
;----------------------------------------------------------------------------;
; Input:
;	SI = WORD array of ports
;	CX = number of ports to show
;----------------------------------------------------------------------------;
SHOW_PORT_COUNT PROC
	JCXZ	PORT_COUNT_NONE			; if no ports, display 'None'
PORT_COUNT_LOOP:
	LODSW	
	CALL	WORD_HEX				; display I/O address in hex
	CALL	SPACE					; separate ports with space
	LOOP	PORT_COUNT_LOOP
	MOV	SI, OFFSET POST_RSEP[1]		; skip leading space in right sep.
	JMP	SHORT POST_END_COL_STR		; display end with sep. in SI and RET
PORT_COUNT_NONE:
	PRINT_SZ  POST_NONE			; display 'None'
	JMP	SHORT POST_END_COL		; display end sep and RET
SHOW_PORT_COUNT ENDP

POST_SYS_CONFIG ENDP

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
;
; Output:
; - SI: beginning of next adjacent string
; - CX: inner text color length = POST_TAB_COL_I
;----------------------------------------------------------------------------;
POST_COL PROC

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
	PUSH	SI				; save end of string
	MOV	SI, OFFSET POST_LSEP	; write separator string with
	CALL	OUT_SZ			;  existing attributes
	MOV	BL, AH			; restore text color
	DEC	SI				; [SI] = previous null char
	MOV	CL, POST_TAB_COL_I	; CX = repeat times
	PUSH	CX				; save for return
	CALL	OUT_SZ_ATTR			; set attributes, skip null string
	POP	CX				; CX = inner text color length
	POP	SI				; restore string position
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
; Same as POST_END_COL and displays a CRLF
;----------------------------------------------------------------------------;
POST_END_COL_NL PROC
	CALL	POST_END_COL
	JMP	CRLF				; write CRLF and RET
POST_END_COL_NL ENDP

;----------------------------------------------------------------------------;
; Write POST column end separator 
;----------------------------------------------------------------------------;
; Display right separator in color POST_CLR_TXT
; Clobbers: BX
;----------------------------------------------------------------------------;
POST_END_COL PROC
	MOV	SI, OFFSET POST_RSEP

;----------------------------------------------------------------------------;
; POST_END_COL_STR: Write POST column end separator
;----------------------------------------------------------------------------;
; Input: CS:SI
;----------------------------------------------------------------------------;
POST_END_COL_STR PROC
	MOV	CX, 2
	MOV	BX, LOW POST_CLR_TXT	; Fall through to OUT_SZ_ATTR and RET

;----------------------------------------------------------------------------;
; Write a zero-terminated string to console with attributes, no cursor move
;----------------------------------------------------------------------------;
; Sets attribute in BL for the next CX number of characters, past end of string.
;
; Input: CS:SI = String, CX = length, BL = attribute, BH = video page
; Output: SI = end of string
;----------------------------------------------------------------------------;
OUT_SZ_ATTR PROC
			IF POST_THEME NE 0	; enable color/attribute display
	PUSH	AX

			IF MDA_ATTR LT 2	; filter MDA attributes
;----------------------------------------------------------------------------;
; Filter MDA attributes - display with intensity attribute only
;
MDA_COLOR_FIX:
	CALL	INT_10_IS_TXT		; CF if MDA
	JNC	OUT_SZ_ATTR_SET		; skip if not MDA
			IF MDA_ATTR EQ 1	; only intensity
	AND	BL, MASK MDIN OR MASK MDFG ; remove MDA blink and background attr
	OR	BL, MASK MDFG		; remove MDA underline attr
			ELSE			; filter all
	MOV	BL, MDA_CH_ATTR <>	; default normal
			ENDIF
			ENDIF
OUT_SZ_ATTR_SET:
	MOV	AX, DBW <9, VID_SP>	; write empty char with attr CX # of times
	INT	10H
	POP	AX				; Fall through to OUT_SZ and RET
			ENDIF			; POST_THEME NE 0

;----------------------------------------------------------------------------;
; Display a zero-terminated string in BIOS at CS:[SI]
;----------------------------------------------------------------------------;
; Input: CS:SI = String, BH = video page
; Size: 24 bytes
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
OUT_SZ ENDP
OUT_SZ_ATTR ENDP
POST_END_COL_STR ENDP
POST_END_COL ENDP

;----------------------------------------------------------------------------;
; Locate cursor to column on current line
;----------------------------------------------------------------------------;
; Input:
; - AL = new col
;
; Size: 23 bytes
;----------------------------------------------------------------------------;
MOVE_COL PROC
			IF CPU_TYPE	EQ CPU_V20
	PUSHA					; preserve all registers
			ELSE
	PUSHX	AX, BX, CX, DX		; must preserve all of these
			ENDIF
	PUSH	AX				; preserve AL on INT 10H call
	MOV	BH, 0 			; video page 0 (flags preserved)
	MOV	AH, 3 			; get cursor position
	INT	10H 				; DH = row, DL = column
	POP	AX
MOVE_COL_SET:
	MOV	DL, AL			; set new column
	MOV	AH, 2 			; set cursor position
	INT	10H 				; row = DH, column = DL
			IF CPU_TYPE	EQ CPU_V20
	POPA					; restore all registers
			ELSE
	POPX	DX, CX, BX, AX
			ENDIF
	RET
MOVE_COL ENDP
POST_COL ENDP

;----------------------------------------------------------------------------;
; Write a space char to console (8 bytes)
;----------------------------------------------------------------------------;
SPACE PROC
	PUSH	AX				; no clobbery AX
	MOV	AX, DBW <0EH, ' '>	; AH = 0Eh, AL = space char
	INT	10H				; send to console
	POP	AX
	RET
SPACE ENDP

;----------------------------------------------------------------------------;
; Write Unsigned word as decimal to console
;----------------------------------------------------------------------------;
; Input: AX value
; Clobbers: AX, BX
; Size: 23 bytes
;----------------------------------------------------------------------------;
OUT_DECU PROC
	MOV	BX, 10			; decimal divisor = 10
OUT_DECU_R:
	PUSH	DX				; save remainder digit / caller DX
	XOR	DX, DX 			; clear high word of dividend
	DIV	BX				; AX = DX:AX / 10, DX = DX:AX % 10
	TEST	AX, AX			; is zero?
	JZ	OUT_DECU_DONE		; loop while AX > 0
	CALL	OUT_DECU_R			; recursive call to next division
OUT_DECU_DONE:
	XCHG	AX, DX			; AL = digit, AH = 0
	XOR	AX, DBW <0EH, '0'>	; ASCII convert digit, AH = 0EH
	INT	10H				; write to console
	POP	DX				; restore digit
	RET
OUT_DECU ENDP

;----------------------------------------------------------------------------;
; Write DWORD BX:AX as HEX to console
;----------------------------------------------------------------------------;
; Input: BX:AX - 32 bit value to write
; WORDS are separated by a colon ex: 1234:ABCD
;
; AX clobbered
; Size: 50 bytes
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
	ROL4	_AL				; AL(low nibble) = AL(high nibble)
			ELSE
		REPT	4
	SHR	AL, 1				; shift high nibble to low nibble
		ENDM
			ENDIF
	CALL	NIB_HEX 			; write low nibble of AL as HEX to console
	POP	AX 				; restore AL

;--------------------------------------------------------------------------
; Write low nibble of AL as HEX to console
;--------------------------------------------------------------------------
NIB_HEX PROC
	AND	AL, 0FH 			; isolate low nibble
	CMP	AL, 0AH 			; if < 0Ah, CF=1 and setup a -1 for ASCII
						;  adjust since 'A'-'9' is 7 (not 6)
	SBB	AL, -('0'+66H+1) 		; BCD bias for ASCII (30h + 66h + CF)
						;  AF if AL < 0Ah, CF = 1
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
	MOV	BH, 0				; video page = 0 (preserve flags)
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

;
; 50 BYTES HERE
;
BYTES_HERE	INT_12

;----------------------------------------------------------------------------;
; INT 12H - Memory Size Determination
;----------------------------------------------------------------------------;
; Output
;	AX = number of contiguous 1k memory blocks found at startup
;----------------------------------------------------------------------------;
		ORG 0F841H
INT_12 PROC
		ASSUME DS:_BDA
	STI 					; interrupts on
	PUSH	DS 				; save DS
	MOV	AX, SEG _BDA
	MOV	DS, AX 			; DS = BDA
	MOV	AX, MEM_SZ_KB 		; AX = DS:[MEM_SZ_KB]
	POP	DS
	IRET
INT_12 ENDP

;----------------------------------------------------------------------------;
; INT 11H - BIOS Equipment Determination / BIOS Equipment Flags
;----------------------------------------------------------------------------;
; Output
;	AX = data stored at BIOS Data Area location 0040:0010
;----------------------------------------------------------------------------;
		ORG 0F84DH
INT_11 PROC
		ASSUME DS:_BDA
	STI 					; interrupts on
	PUSH	DS 				; save DS
	MOV	AX, SEG _BDA
	MOV	DS, AX 			; DS = BDA
	MOV	AX, EQUIP_FLAGS
	POP	DS
	IRET
INT_11 ENDP

;----------------------------------------------------------------------------;
; INT 15 - System BIOS Services / Cassette
;----------------------------------------------------------------------------;
;	INT 15,0  Turn cassette motor on
;	INT 15,1  Turn cassette motor off
;	INT 15,2  Read blocks from cassette
;	INT 15,3  Write blocks to cassette
;
; Output:
;	CF = 1, AH = 86H (unsupported/no cassette present)
;
; https://stanislavs.org/helppc/int_15.html
; http://www.ctyme.com/intr/int-15.htm
; http://www.techhelpmanual.com/212-int_15h__at_extended_services___apm.html
;----------------------------------------------------------------------------;
		ORG 0F859H
INT_15 PROC
	STI					; return with interrupts enabled
			IF CASSETTE EQ 1
	CMP	AH, 3				; cassette function 0-3?
	JBE	INT_15_CASS
			ENDIF

	MOV	AH, 86H 			; return with unsupported function
INT_15_EXIT:
	CMP	AH, 1				; set CF if error (AH > 0)
	CMC
	IRET_F				; IRET with current flags

			IF CASSETTE EQ 1
;----------------------------------------------------------------------------;
; INT 15H - 5150 Cassette
;----------------------------------------------------------------------------;
; Input:
;	ZF if AH = 3 (result of 'CMP AH, 3')
;
;----------------------------------------------------------------------------;
; Huge thx to @Raffzahn for clean room specs!
;
; Further reading:
;  https://nerdlypleasures.blogspot.com/2014/04/tape-cassettes-storage-with-ibm-pc-and.html
;  http://fileformats.archiveteam.org/wiki/IBM_PC_data_cassette
;  http://brutmanlabs.org/Cassette_Waveforms/Cassette_Waveforms.html
;----------------------------------------------------------------------------;
INT_15_CASS PROC
			ASSUME DS:_BDA
	PUSH	DS
	PUSH	SI
	PUSH	DX				; scratch register
	MOV	SI, OFFSET CAS_CRC	; used for CAS_CRC and BIOS_BREAK offsets
	MOV	DX, SEG _BDA		; DH = 0, DL = 40H
	MOV	DS, DX			; DS = BDA segment
	MOV	_BIOS_BREAK, DH		; clear BIOS break key flag
	MOV	AL, AH			; AL = function
	LAHF					; save 'CMP AH, 3' flags
	DEC	AL				; is motor off function?
	JZ	CAS_MOTOR_OFF_DONE	; turn motor off and exit
						; otherwise fall through, turn on motor
						; and do read/write operation or exit

;----------------------------------------------------------------------------;
; INT 15,0 - Turn Cassette Motor On
;----------------------------------------------------------------------------;
; Input:
;	AH = 00
;
; - all programs using the cassette must actually turn on
;	the device before use
; - there is a noticeable delay between turn-on and device ready
; - a noticeable clicking noise can be heard by switching the
;	cassette on and off
;----------------------------------------------------------------------------;

CAS_MOTOR_ON:
;----------------------------------------------------------------------------;
; - Disable Speaker
; - Switch on Motor
; - Wait ca 0.5s
;
	IN	AL, PPI_B			; read current PPI B
	AND	AL, NOT MASK PBSP	AND NOT MASK PBCM	; Disable Speaker and
						; turn on (clear) motor bit
	OUT	PPI_B, AL			; send to PPI B
	SAHF					; restore 'CMP AH, 3' flags
	JPE	CAS_MOTOR_WAIT		; jump if read/write
						; otherwise fall through to exit

;----------------------------------------------------------------------------;
; Return with success
;
INT_15_DONE_OK:
	MOV	AH, 0				; return with success

;----------------------------------------------------------------------------;
; Return with status in AH 
;
INT_15_DONE:
	POP	DX				; restore working registers

INT_15_DONE_NO_DX:			; return without restoring DX
	POP	SI
	POP	DS
	JMP	SHORT INT_15_EXIT

;----------------------------------------------------------------------------;
; Turn off motor and return success (only read operation returns non-success)
;
CAS_MOTOR_OFF_DONE:
	CALL	CAS_TIMER_ON_MOTOR_OFF		
	JMP	SHORT INT_15_DONE_OK	; return with success

;----------------------------------------------------------------------------;
; Re-enable timer and turn off motor
;
CAS_TIMER_ON_MOTOR_OFF PROC
	IN	AL, INT_IMR			; Re-enable timer interrupt
	AND	AL, NOT MASK IRQ0		; unmask IRQ 0 (INT 8 Timer)
	OUT	INT_IMR, AL
CAS_TIMER_ON_MOTOR_OFF ENDP

;----------------------------------------------------------------------------;
; INT 15,1 - Turn Cassette Motor Off
;----------------------------------------------------------------------------;
; Input:
;	AH = 01
;
; - all programs using the cassette should turn off
;	the device after use
; - a noticeable clicking noise can be heard by switching the
;	cassette on and off
;----------------------------------------------------------------------------;
CAS_MOTOR_OFF PROC
	IN	AL, PPI_B			; read current PPI port B status
	OR	AL, MASK PBCM 		; turn off (SET) motor bit
	OUT	PPI_B, AL			; write back to port B	
	RET
CAS_MOTOR_OFF ENDP

;----------------------------------------------------------------------------;
; Is Read/Write operation: Wait 0.5 sec for motor spinup
;
CAS_MOTOR_WAIT:
	PUSHF					; save flags
	MOV	AX, 500			; delay for 500ms
	CALL	IO_DELAY_MS

;----------------------------------------------------------------------------;
; Disable "noisy" INT 08h timer interrupt (could affect timing)
;
	IN	AL, INT_IMR			; read IMR register
	OR	AL, MASK IRQ0		; mask IRQ 0 (INT 8 Timer)
	OUT	INT_IMR, AL			; write IMR

	POPF					; ZF if write, NZ if read
	JZ	CAS_WRITE			; AH = 3 write
	JMP	NEAR PTR CAS_READ		; near jump to read

;----------------------------------------------------------------------------;
; INT 15,3 - Write Blocks to Cassette
;----------------------------------------------------------------------------;
; Write a "chunk" of blocks to tape:
;
; Input:
;	AH = 03
;	CX = count of bytes to write
;	ES:BX = pointer to data buffer
;
; Output:
;	AX clobbered
;	CX = zero
;	ES:BX = pointer to byte following last byte written
;	Flags preserved
;----------------------------------------------------------------------------;
; Format:
; - One bit zero  (to start at defined timing)
; - 256 bytes FFh (=2048 bits of 1) (Leader)
; - One bit zero  (for sync)
; - One byte 16h  (sync byte - MSB first)
; - 1..n Data Blocks
; - 4 bytes FFh   (=32 bits of 1)
;
; Notes:
; - data is actually written in 256 byte blocks
; - if CX is less than 256, then the block is padded
; - no error detection/correction is available for writing
;----------------------------------------------------------------------------;
;       1 |			- PBSP	0=turn off speaker, 1=turn on
;        0|			- PBST	0=turn off timer 2, 1=turn on
;----------------------------------------------------------------------------;
CAS_WRITE PROC

;----------------------------------------------------------------------------;
; Set Timer 2 to mode square and enable
;
	MOV	AL, PIT_CW <2, 11B, 3>	; Select Timer 2, LE, Mode 3 (square), Binary
	OUT	PIT_CTRL, AL		; (10 11 011 0) Send to PIT control word (43H)
	IN	AL, PPI_B			; read PPI B
	OR	AL, MASK PBST		; turn on timer 2
	OUT	PPI_B, AL			; send to PPI B

;----------------------------------------------------------------------------;
; One bit zero (to start at defined timing)
;
	CALL	CAS_WRITE_BIT		; start output bit is 0 (already NC from OR)

;----------------------------------------------------------------------------;
; 256 bytes FFh (=2048 bits of 1) (Leader)
;
	PUSH	CX				; save outer byte loop counter
CAS_WRITE_LEADER:
	STC					; leader output bit is 1
	MOV	CX, 256 * 8			; leader is 2048 bits
CAS_WRITE_LEADER_LOOP:
	CALL	CAS_WRITE_BIT		; set timer to correct bit, wait for full cycle
	LOOP	CAS_WRITE_LEADER_LOOP
	POP	CX				; restore outer byte loop counter

;----------------------------------------------------------------------------;
; One bit zero (for sync)
;
	CLC					; sync output bit is 0
	CALL	CAS_WRITE_BIT

;----------------------------------------------------------------------------;
; One byte 16h (sync byte - MSB first)
;
	MOV	AL, SYN			; SYN C0 control char
	CALL	CAS_WRITE_BYTE		; write sync byte

;----------------------------------------------------------------------------;
; CAS_WRITE_BLOCKS: Output 1..n Data Blocks
;----------------------------------------------------------------------------;
;- Output loop (BLOCK)
;  - Init CRC
;  - Block loop (BYTE)
;
; Input: CX = blocks to write
;----------------------------------------------------------------------------;
CAS_WRITE_BLOCKS PROC

;----------------------------------------------------------------------------;
; CAS_WRITE_BLOCK: loop until 256 bytes transfered
;----------------------------------------------------------------------------;
; - Fetch byte if not exhausted
; - Byte loop (BIT)
;
CAS_WRITE_BLOCK PROC
	MOV	_CAS_CRC, CAS_CRC_PRE	; Init CRC preset
	XOR	DX, DX			; block counter DX = 0
CAS_WRITE_BLOCK_LOOP:
	MOV	AL, ES:[BX]			; AL = next byte
	INC	BX
	CALL	CAS_WRITE_BYTE		; write to cassette
	DEC	DL				; loop until 00
	LOOPNZ CAS_WRITE_BLOCK_LOOP	; loop while DX > 0 and CX > 0
	JZ	CAS_WRITE_CRC		; if DX = 0, current block is done

;----------------------------------------------------------------------------;
; CX is 0, DX > 0 - done writing bytes, fill the remaining space in the
; 256 byte block with same char.
;
CAS_WRITE_BLOCK_PAD:
	XCHG	CX, DX			; otherwise write out the rest
CAS_WRITE_PAD_LOOP:
	CALL	CAS_WRITE_BYTE
	LOOP	CAS_WRITE_PAD_LOOP
	XCHG	CX, DX			; restore CX

;----------------------------------------------------------------------------;
; Done writing block and DX = 0
; - Write One's complement of CRC to cassette
;
CAS_WRITE_CRC:
	MOV	AX, _CAS_CRC		; get working CRC
	NOT	AX				; one's complement it
	CALL	CAS_WRITE_WORD		; write to cassette

CAS_WRITE_BLOCK ENDP

;----------------------------------------------------------------------------;
;- Do output loop while still input bytes
;
	INC	CX				; any more bytes left to write?
	LOOP	CAS_WRITE_BLOCK		; write another block if so

CAS_WRITE_BLOCKS ENDP

;----------------------------------------------------------------------------;
; Finish transfer
;----------------------------------------------------------------------------;
; Write 4 Byte FF trailer (32 bits of 1) / 4 bytes FFh   (=32 bits of 1)
;
CAS_WRITE_TRAILER:
	STC					; trailer output bit is 1
	MOV	CL, 4 * 8			; trailer is 4 bytes
CAS_WRITE_TRAILER_LOOP:
	CALL	CAS_WRITE_BIT		; set timer to CF bit, wait for full cycle
	LOOP	CAS_WRITE_TRAILER_LOOP

;----------------------------------------------------------------------------;
;- Turn off timer 2
;- Set Timer 2 to 1
;
	MOV	AL, PIT_CW <2, 11B, 0>	; Select Timer 2, LE, Mode off, Binary
	OUT	PIT_CTRL, AL		; (10 11 000 0) Send to PIT control word

;----------------------------------------------------------------------------;
;- Re-enable INT 8 timer interrupt
;- Switch Motor off and exit
;
	JMP	 SHORT CAS_MOTOR_OFF_DONE

;----------------------------------------------------------------------------;
; CAS_WRITE_BIT: Write a single bit to tape
;----------------------------------------------------------------------------;
; Input:
; 	CF bit: 1 or 0 (preserved)
;
; AL preserved, AH clobbered
;----------------------------------------------------------------------------;
; Things you must do:
;
; - Extract MSB (RCL)
; - Write 0 or 1
; 	- 0 = 2.015 KHz (592 timer cycles)
;	- 1 = 1.007 KHz (1184 timer cycles)
; - Add to CRC message
;----------------------------------------------------------------------------;
CAS_WRITE_BIT PROC
	LAHF					; preserve CF flag
	PUSH	AX				; preserve AX
	MOV	AX, BEEP_1K7		; set for 1 = ~1 ms  (1.007 KHz = 1,193,182/1184)
	JC	CAS_START_TIMER		; if input bit is a 1, AX already set
	SHR	AX, 1				; set for 0 = ~0.5ms (2.015 KHz = 1,193,182/592)
CAS_START_TIMER:
	OUT	PIT_CH2, AL			; send low byte to timer
	XCHG	AL, AH			; select high byte
	OUT	PIT_CH2, AL			; send high byte to timer

;----------------------------------------------------------------------------;
; Read Timer 2 and wait a full rising and falling flank
;
CAS_WRITE_RISE:
	IN	AL, PPI_C			; read PPI C
	TEST	AL, MASK PCT2		; is cassette output low?
	JZ	CAS_WRITE_RISE		; loop until rise
CAS_WRITE_FALL:
	IN	AL, PPI_C			; read PPI C
	TEST	AL, MASK PCT2		; is cassette output high?
	JNZ	CAS_WRITE_FALL		; loop until fall
	POP	AX				; restore AL for next call
	SAHF					; restore CF flag for next call
	RET
CAS_WRITE_BIT ENDP

;----------------------------------------------------------------------------;
; CAS_WRITE_WORD: Write a little endian word to tape
;----------------------------------------------------------------------------;
; Input:
; 	AX: word to write (preserved)
;----------------------------------------------------------------------------;
CAS_WRITE_WORD PROC
	XCHG	AH, AL			; MSB first
	CALL	CAS_WRITE_BYTE		; write MSB
	XCHG	AH, AL			; LSB
						; fall through to write LSB

;----------------------------------------------------------------------------;
; CAS_WRITE_BYTE: Write a single byte to tape
;----------------------------------------------------------------------------;
; Input:
; 	AL: byte to write (preserved)
;----------------------------------------------------------------------------;
CAS_WRITE_BYTE PROC
	PUSH	AX
	PUSH	CX
	MOV	CX, 8				; loop 8 bits
CAS_WRITE_BYTE_LOOP:
	SHL	AL, 1				; CF = next bit to write
	CALL	CAS_WRITE_BIT		; write bit in CF
	CALL	CAS_CRC_ADD			; add to working CRC
	LOOP	CAS_WRITE_BYTE_LOOP
	POP	CX
	POP	AX
	RET
CAS_WRITE_BYTE ENDP
CAS_WRITE_WORD ENDP

CAS_WRITE ENDP

;----------------------------------------------------------------------------; 
; INT 15,2 - Read Blocks from Cassette 
;----------------------------------------------------------------------------; 
; Input:
;	AH = 02
;	CX = count of bytes to read
;	ES:BX = pointer to data buffer
;
; Output:
;	CF = 1 if error
;	AH = result:
;	  00h = successful
;	  01h = CRC error
;	  02h = bad tape signals / data transition lost
;	  04h = no data / timeout / general failure
;
;	DX = count of bytes actually read
;	ES:BX = pointer to byte following last byte read
;----------------------------------------------------------------------------;
; Notes:
;
; - Data is transferred in 256 byte blocks, though only the
;	number of bytes requested are actually stored
; - Mask INT 8 Timer interrupts (IRQ 0) during actual read 
;	(could affect timing)
;
; Data Format:
;
; - One bit zero  (to start at defined timing)
; - 256 bytes FFh (2048 bits of 1) (Leader)
; - One bit zero  (for sync)
; - One byte 16h  (sync byte - MSB first)
; - 1..n Data Blocks
; - 4 bytes FFh   (=32 bits of 1)
;----------------------------------------------------------------------------;
CAS_READ PROC
	PUSH	BP				; call-preserve BP
	MOV	BP, 5				; set timeout/retry counter
	PUSH	DI
	MOV	DI, BX			; DI = output buffer
	PUSH	CX				; save bytes to read

;----------------------------------------------------------------------------;
; CAS_READ_HEADER_START: Search for leader
;----------------------------------------------------------------------------;
; - Must read at least 32 bytes of FFh
; - Timeout/Error if > 1000 invalid bytes are read
; - Must check for Ctrl-Break in all loops
; - Retry reading header 5 times
;----------------------------------------------------------------------------;
CAS_READ_HEADER_START:
	IN	AL, PPI_C			; read PPI C
	AND	AL, MASK PCCI		; mask only cassette input
	MOV	CAS_PREV, AL		; save initial value

;----------------------------------------------------------------------------;
; Continue reading until a valid cycle detected or timeout
;
	MOV	CX, 1000 * 8 * 2		; timeout is 1000 bytes
CAS_READ_HEADER_LOOP:
	TEST	_BIOS_BREAK, MASK KBRK	; Test BIOS break flag
	JNZ	CAS_READ_ERR_1		; Break key was hit
	CALL	CAS_READ_CYCLE		; loop until bit detected or timeout
	LOOPZ	CAS_READ_HEADER_LOOP
	JCXZ	CAS_READ_ERR		; return with general error

;----------------------------------------------------------------------------;
; Read Leader up to sync bit:
; - If read error, start over from beginning
; - Read at least 32 consecutive FFh bytes
;	- if >= 32 bytes
;		- if 0, read corresponding high cycle and continue
;		- if 1, continue reading until sync bit (0) detected
;	- if < 32 bytes and 0 read, start over from beginning
;
	MOV	CX, 32 * 8 * 2		; leader must be at least 32 bytes
CAS_READ_HEADER_LOOP_1:
	TEST	_BIOS_BREAK, MASK KBRK	; Test BIOS break flag
CAS_READ_ERR_1:				; (short jump hack)
	JNZ	CAS_READ_ERR		; exit if break key was hit

;----------------------------------------------------------------------------;
; Read cycle transition, start over if error
;
	CALL	CAS_READ_CYCLE		; read (ZF if failure, NZ if success)
	JZ	CAS_READ_HEADER_START	; if error, start over 32 byte count

;----------------------------------------------------------------------------;
; Calculate cycle length - is a 1 or 0?
;
	CMP	DX, (BEEP_1K7+BEEP_2K)/2; is cycle > 1 length + 33%?
	JCXZ	CAS_READ_HEADER_SYNC	; if at least 32 FFh bytes, check for sync bit
	JB	CAS_READ_HEADER_START	; if a 0 and not 32 FFh's, start over
	LOOP	CAS_READ_HEADER_LOOP_1	; otherwise decrement counter of 1's.

;----------------------------------------------------------------------------;
; At least 32 x 1's have been found (CX = 0):
; - if bit is 0, it is the sync bit
; - if bit is 1, keep reading out the remaining 1's
;
CAS_READ_HEADER_SYNC:
	JAE	CAS_READ_HEADER_LOOP_1	; jump if 1 is read (keep reading for 1's)
	CALL	CAS_READ_CYCLE		; wait for sync bit high cycle to complete

;----------------------------------------------------------------------------;
; Read and verify sync byte
;
	CALL	CAS_READ_BYTE		; read first byte
	CMP	AL, SYN			; is sync byte?
	JNE	CAS_READ_ERR		; error if not

;----------------------------------------------------------------------------;
; CAS_READ_BLOCKS
;----------------------------------------------------------------------------;
; - Reset CRC to initial preset
; - Always loop 256 times (bytes)
; - Check for Ctrl-Break
; - If successful read, write to ES:[DI]
; - If failed read, exit with data error (04h)
; - If requested bytes < 256, read (and discard) remaining bytes
; - Read and verify CRC. If bad CRC exit with CRC error (01h)
; - If CX > 0, restart block loop
;----------------------------------------------------------------------------;
	POP	CX				; restore counter
	PUSH	CX				; rebalance stack
CAS_READ_BLOCKS PROC
	MOV	_CAS_CRC, CAS_CRC_PRE	; set CRC to initial preset
	MOV	BH, 0				; loop 256 bytes
CAS_READ_BLOCK_LOOP:
	TEST	_BIOS_BREAK, MASK KBRK	; Test BIOS break flag
	JNZ	CAS_READ_ERR		; exit if break key was hit
	CALL	CAS_READ_BYTE		; read next full byte
	MOV	AH, 2				; data error
	JC	CAS_READ_EXIT		; exit if error
	STOSB					; write to output buffer
	DEC	BH				; dec block counter
	LOOPNZ CAS_READ_BLOCK_LOOP	; loop if block and byte counters > 0
	JZ	CAS_READ_VERIFY_CRC	; if end of requested bytes, jump to CRC

;----------------------------------------------------------------------------;
; CX is 0, DX > 0 - done reading bytes, skip the remaining padding bytes
;
	MOV	CL, BH			; CX = remaining bytes to read
CAS_READ_BLOCK_PAD:
	CALL	CAS_READ_BYTE		; read next full byte
	JC	CAS_READ_ERR		; exit if error
	LOOP	CAS_READ_BLOCK_PAD

;----------------------------------------------------------------------------;
; Verify CRC - read CRC bytes and compare to known residue
;
; https://stackoverflow.com/questions/241605/crc-preset-and-residue
;
CAS_READ_VERIFY_CRC:
	CALL	CAS_READ_WORD		; read final two CRC bytes, adding to CRC
	JC	CAS_READ_ERR		; 
	CMP	_CAS_CRC, CAS_CRC_RES	; is expected CRC-CCITT residue (01D0Fh)?
	MOV	AH, 1				; CRC error
	JNE	CAS_READ_EXIT
	INC	CX				; any more bytes left to read?
	LOOP	CAS_READ_BLOCKS		; if so, read another block
	MOV	AH, 0				; no error
	JMP	SHORT CAS_READ_EXIT

CAS_READ_BLOCKS ENDP

;----------------------------------------------------------------------------;
; General / timeout error
;
CAS_READ_ERR PROC
	DEC	BP				; dec retry counter
	JNZ	CAS_READ_HEADER_START	; if not 0, retry header read
	MOV	AH, 4				; general/timeout error
CAS_READ_ERR ENDP

;----------------------------------------------------------------------------;
; Re-enable interrupts, set return values
;
CAS_READ_EXIT:
	POP	DX				; DX = original bytes to read
	SUB	DX, CX			; DX = actual bytes read (subtract bytes remaining)
	MOV	BX, DI			; BX = pointer to end of output buffer
	POP	DI				; restore original DI
	POP	BP
	POP	DS				; discard original DX
	CALL	CAS_TIMER_ON_MOTOR_OFF	; Re-enable timer and motor off
	JMP	INT_15_DONE_NO_DX		; exit without restoring DX

;----------------------------------------------------------------------------;
; CAS_READ_CYCLE: read 1 cycle
;----------------------------------------------------------------------------;
; Time a single cycle of a bit
; Output:
;	AX = counter reading
;	DX = lendth of cycle in counter ticks
;	NZ if success
;	ZF if failure (cycle exceeded maximum possible length)
;----------------------------------------------------------------------------;
CAS_READ_CYCLE PROC
	PUSH	CX				; call-preserve CX
	MOV	CX, 100			; timeout value
	MOV	AH, _CAS_PREV		; AH last input register value
CAS_READ_CYCLE_LOOP:
	IN	AL, PPI_C			; read PPI C
	AND	AL, MASK PCCI		; mask only cassette input
	CMP	AL, AH			; ZF if reading is same as last
	LOOPZ	CAS_READ_CYCLE_LOOP	; loop until change or timeout
	MOV	CAS_PREV, AL		; save new input value
	CALL	IO_WAIT_LATCH		; latch and read PIT counter into AX
	MOV	DX, _CAS_TIME_CNT		; DX = last counter reading
	SUB	DX, AX			; DX = difference of last and current
	MOV	CAS_TIME_CNT, AX		; update counter read
	TEST	CX, CX			; ZF if timeout, NZ if success
	POP	CX
	RET
CAS_READ_CYCLE ENDP
CAS_READ ENDP

INT_15_CASS ENDP
			ENDIF			; ENDIF CASSETTE EQ 1
INT_15 ENDP

;----------------------------------------------------------------------------;
;
; Features not included in 5150/Cassette build go below:
;
;----------------------------------------------------------------------------;

		IF POST_HD_PARMS EQ 1
;----------------------------------------------------------------------------;
; Display Hard Drive Parameters
;----------------------------------------------------------------------------;
; Display info for POST in drive DL
;
; Input:
;	DL = drive #
;
; Clobbers: AX, BX
;
; Size: 100 bytes
;----------------------------------------------------------------------------;
SHOW_DISK_PARAMS PROC
	PUSHX	CX, DX				; call preserve working registers
	PUSH	DX					; save drive ID
	CALL	GET_DISK_PARAMS			; AL=heads, BX=cyl, CL=sec, DL=#drives
	POP	DX					; restore drive ID
	JC	SHOW_DISK_PARAMS_DONE		; exit if error getting drive
	PUSH	CX					; save sectors/track for CHS display
	PUSH	AX					; save heads
	PUSH	BX					; save cylinders

;----------------------------------------------------------------------------;
; Display Drive letter
;
	SET_SZ_ATTR	 POST_CLR_TXT, 1, 1	; set next char to be text color
	XCHG	AX, DX				; AL = drive ID, DX = # of heads
	AND	AL, 0011B				; only drives 0-3
	ADD	AL, 'C'				; convert to drive letter
	CALL	OUT_CHAR

;----------------------------------------------------------------------------;
; Display HD size: MiB = C*H*S*512/1024/1024 = C*H*S/2048
;
	XCHG	AX, DX				; AX = # of heads
	MUL	CL					; AX = heads * sectors
	MUL	BX					; DX:AX = heads * sectors * cyl
	MOV	CX, 1024 * (1024 / 512)		; AX = DX:AX / 2048
	DIV	CX					; (size in MB)
	POST_COL_1	POST_HD, POST_CLR_VAL1	; start column 1, SI = POST_MB
	CALL	OUT_DECU				; print size in MB
	CALL	OUT_SZ				; 'MB' (SI = POST_MB from above)
	POP	AX					; AX = cylinders
	POST_COL_END				; end column 1

;----------------------------------------------------------------------------;
; Display HD geometry: Cylinders Heads Sectors
;
	POST_COL_2	POST_CHS, POST_CLR_VAL1 ; start column 2
	CALL	OUT_DECU				; print # cylinders
	CALL	SPACE
	POP	AX					; AX = heads
	CALL	OUT_DECU_R				; print # heads
	CALL	SPACE
	POP	AX					; AX = sectors/track
	CALL	OUT_DECU_R				; print sec/track
	POST_COL_END_NL				; end column 2

SHOW_DISK_PARAMS_DONE:
	POPX	DX, CX				; restore working registers
	RET

POST_CHS	DB	'CHS', 0			; CHS column 2 label

SHOW_DISK_PARAMS ENDP
		ENDIF

		IF RANDOM_TAGLINE EQ 1
;----------------------------------------------------------------------------;
; Display BIOS name and random tagline
;----------------------------------------------------------------------------;
; String is chosen from low two bits of BP
; Clobbers: AX
; Size: 111 bytes
;----------------------------------------------------------------------------;
HELLO_RAND_TAGLINE PROC
	PRINT_SZ  TOP_BANNER		; display main banner
	MOV	AX, BP			; get random bits from BP
	POST_FLAG_CLR  GRND		; clear random bits from BP
	AND	AX, MASK GRND		; only low 2 bits
	XCHG	AX, SI			; SI = string offset table
	SHL	SI, 1				; word align
	MOV	SI, CS:TAGS[SI]		; SI = chosen tagline offset
	PRINT_SZ  SI			; display tagline
	MOV	SI, OFFSET COPYRIGHT	; display copyright message
	JMP	NEAR PTR OUTLN_SZ		; write and RET

;----------------------------------------------------------------------------;
; Three additional random taglines
;
TAG1		DB	'On the leading trailing edge', 0
TAG2		DB	'Abort, Retry, Succeed', 0
TAG3		DB	'When life gives you lemonade', 0
;		DB	'Ready to believe you', 0
;		DB	'An Energy Star Foe', 0
;		DB	'Now 97% asbestos-free', 0
;		DB	'Ought to be enough for anybody', 0

;----------------------------------------------------------------------------;
; Offset table for taglines
;
TAGS		DW	OFFSET TAG0, OFFSET TAG1, OFFSET TAG2, OFFSET TAG3

HELLO_RAND_TAGLINE ENDP
		ENDIF

		IF POST_OPT_ROM EQ 1
;----------------------------------------------------------------------------;
; ROM scan loading - display segment, size and checksum error
;----------------------------------------------------------------------------;
; Input:
;	AX = BIOS size in 512 byte blocks
;	DI = Option ROM scan end segment
;	DL = ROM checksum value
;
; Clobbers: BX, DX, BP
;
; Size: 99 bytes
;----------------------------------------------------------------------------;
ROM_SCAN_POST PROC
	XCHG	AX, BP					; preserve AX ROM size
	PUSH	SI						; working register
	PUSHF							; and flags

;----------------------------------------------------------------------------;
; Ensure this is not scanning a display option ROM - could crash if video
; ISR not is installed
;
	CMP	DI, 0C800H					; is video ROM scan?
	JBE	ROM_SCAN_POST_EXIT			; exit if so

;----------------------------------------------------------------------------;
; Display ROM column
;
	POST_COL_1  S_OPT_ROM, POST_CLR_VAL2	; start ROM column label
	MOV	AX, DS					; AX = ROM segment
	CALL	WORD_HEX					; display as hex
	POST_COL_END					; end column 1

;----------------------------------------------------------------------------;
; Display Size or Checksum error column
;
	POPF							; restore checksum flag
	PUSHF							; re-save flag
	JNZ	ROM_SCAN_POST_CHK				; jump if checksum error
	POST_COL_2  S_OPT_SIZE, POST_CLR_VAL2	; start 'Size' column 2
	MOV	AX, BP					; restore ROM size
	SHR	AX, 1						; convert to KB
	CALL	OUT_DECU					; write size as decimal
	PRINT_SZ	S_OPT_K				; display KB unit

ROM_SCAN_POST_DONE:
	POST_COL_END_NL					; end column 2

ROM_SCAN_POST_EXIT:
	POPF							; restore checksum result flag
	POP	SI
	XCHG	AX, BP					; restore AX
	RET

;----------------------------------------------------------------------------;
; Display checksum error
;
ROM_SCAN_POST_CHK:
	POST_COL_2  POST_ERR_ERR, RED			; 'Error' with red text
	PRINT_SZ	S_OPT_CHK				; display 'Checksum' message
	MOV	AL, DL					; AL = computed checksum
	CALL	BYTE_HEX					; write as hex byte
	JMP	ROM_SCAN_POST_DONE			; end column and return

S_OPT_ROM	DB	'ROM', 0
S_OPT_SIZE	DB	'Size', 0
S_OPT_CHK	DB	'Chksum ', 0			; Checksum
S_OPT_K	DB	' ', POST_K_UNIT, 0

ROM_SCAN_POST ENDP
		ENDIF

		IF LIGHT_PEN EQ 1
;----------------------------------------------------------------------------;
; INT 10,4 - Read Light Pen Position
;----------------------------------------------------------------------------;
; Return:
;	AH = 0 light pen switch not triggered
;	   = 1 light pen triggered
;	BX = pixel column (0-319 or 0-639, mode dependent)
;	CH = raster line (0-199) (CGA and EGA modes 4, 5 and 6)
;	CX = raster line (EGA modes except 4, 5 and 6)
;	DH = row (0-24)
;	DL = column (0-79 or 0-79 mode dependent)
;
; Size: 128 bytes
;
; Thx to @Raffzahn for "clean room" specs.
;----------------------------------------------------------------------------;
; https://nerdlypleasures.blogspot.com/2016/05/ibms-cga-hardware-explained.html
; https://www.reenigne.org/blog/cga-reading-the-current-beam-position-with-the-lightpen-latch/
; https://scalibq.wordpress.com/2015/04/19/8088-mph-sprites-where-were-going-we-dont-need-sprites/
;----------------------------------------------------------------------------;
INT_10_4 PROC
	MOV	DI, DX			; save caller DX
	MOV	DX, VID_PORT		; 6845 I/O port address (3x4h)
	ADD	DX, CGA_STAT-CGA_IDX	; DX = 3xAh status port
	IN	AL, DX			; read Status Register
	XOR	AH, AH			; AH = 0 (switch not triggered)
	TEST	AL, MASK VSPE		; light pen on? (/0100b) (0=on, 1=off)
	JNZ	INT_10_4_RESET		; if light pen off, reset latch and exit
	TEST	AL, MASK VSPT		; light pen trigger set? (0010b) (0=not set, 1=set)
	JZ	INT_10_4_EXIT		; if not set, just exit

;----------------------------------------------------------------------------;
; Trigger is set, read light pen word from 6845. Address Register is latched
; into light pen register when LPSTB pulses high.
;
	SUB	DX, CGA_STAT-CGA_IDX	; DX = 3x4h index port
	MOV	AL, 10H			; light pen index (MSB)
	OUT	DX, AL			; select index
	INC	DX				; DX = 3x5h data port
	IN	AL, DX			; read MSB
	MOV	AH, AL			; save MSB
	DEC	DX				; DX = 3x4h index port
	MOV	AL, 11H			; light pen index (LSB)
	OUT	DX, AL			; select index
	INC	DX				; DX = 3x5h data port
	IN	AL, DX			; read LSB

;----------------------------------------------------------------------------;
; Calculate screen location from latched address. Address needs a
; "calibration factor" applied due to "slow light pen response".
;
; -3: 0,1,4,5,6 (CGA low-res text/gfx)
; -5: 2,3 (CGA hi-res text)
; -4: 7 (MDA text)
;
	MOV	BX, VID_SEG			; BX = start offset of video memory
	SHR	BX, 1				; byte align index
	ADD	BX, 3				; BX = minimum calibration factor
	XCHG	AX, CX			; save AX
	CALL	INT_10_IS_TXT		; ZF=1 if text, ZF=0 if gfx, CF=1 if MDA
	LAHF					; save video type flags for later
	JNZ	INT_10_4_CAL_2		; skip if modes 4,5,6
	JC	INT_10_4_CAL_1		; +1 if MDA mode 7
	CMP	AL, 2				; AL < 2?
	JL	INT_10_4_CAL_2		; skip if modes 0,1 (+0)
	INC	BX				; +1 for modes 2,3
INT_10_4_CAL_1:
	INC	BX				; +1 for modes 2,3,7
INT_10_4_CAL_2:
	SUB	CX, BX			; CX = calibrated memory regen offset
	JAE	INT_10_4_CAL_DONE		; is result < 0?
	XOR	CX, CX			; if so, use base offset 0000
INT_10_4_CAL_DONE:
	SAHF					; ZF=1 if text, ZF=0 if gfx
	XCHG	AX, CX			; restore AX, CL = video mode
	JNZ	INT_10_4_GFX		; jump if graphics mode

;----------------------------------------------------------------------------;
; Calculate output for Text mode
;
; Input:
;	AX = calibrated memory offset
; Output:
;	BX = pixel column (0-319 or 0-639)
;	CH = raster line (0-199)
;	DI = (value for DX) DH = row (0-24), DL = column (0-79)
;----------------------------------------------------------------------------;
; Formula:
;	DX = calibrated memory offset (AX) DIV video columns (DH=row, DL=col)
;	BX = col (DL) * 8
;	CH = row (DH) * 8
;----------------------------------------------------------------------------;
INT_10_4_TXT:
	MOV	CL, 3				; shift counter 3 (for * 8)
	DIV	BYTE PTR VID_COLS		; divide value by char/line
	XCHG	AH, AL			; AH = row, AL = col
	MOV	DI, AX			; DH = row, DL = col
	MOV	CH, AH			; CH = row
	SHL	CH, CL			; CH = raster line (col * 8)
	CBW					; AH = 0, AL = col
	SHL	AX, CL			; AX = col * 8
	XCHG	AX, BX			; BX = pixel column

;----------------------------------------------------------------------------;
; DONE: Clear latch and return with AH = 1
;
INT_10_4_DONE:
	MOV	AH, 1				; light pen triggered

;----------------------------------------------------------------------------;
; Light pen strobe reset
;
	ADD	DX, CGA_PEN_RST-CGA_DATA	; pen latch register
INT_10_4_RESET:
	OUT	DX, AL			; reset light pen latch

INT_10_4_EXIT:
	MOV	DX, DI			; restore/output DX
	RET

;----------------------------------------------------------------------------;
; Calculate output for GFX mode
;
; Input:
;	AX = calibrated memory offset
;	CL = video mode
; Output:
;	BX = pixel column (0-319 or 0-639)
;	CH = raster line (0-199)
;	DI = (value for DX) DH = row (0-24), DL = column (0-79)
;----------------------------------------------------------------------------;
; Formula:
; 	DX = calibrated memory offset (AX) DIV 40 (DH=row, DL=col)
;	CH = row (DH) * 2
;	DH = row (DH) / 4
;	if ( high res ):
; 		DL = col (DL) * 2
;	BX = DL * 8
;
; Note: output registers used as variable names in comments below.
;----------------------------------------------------------------------------;
INT_10_4_GFX:
	MOV	CH, 40			; divide value by 40
	DIV	CH				; AL = row, AH = col
	XCHG	AH, AL			; AH = row, AL = col
	MOV	CH, AH			; CH = row (DH) * 2
	SHL	CH, 1				; adjust for odd/even fields

;----------------------------------------------------------------------------;
; Multiply column according to graphics mode
;
	CMP	CL, 6				; is 640x200 mode?
	JNE	INT_10_4_LOW		; if not, jump
	SHL	AL, 1				; DL = col (DL) * 2
INT_10_4_LOW:
	MOV	CL, 3				; shift counter 3 for * 8
	MOV	BX, AX			; BL = DL for pixel column
	CBW					; zero extend BL
	SHL	AX, CL			; BX = DL * 8
	XCHG	AX, BX			; return as BX
	DEC	CX				; shift counter 2 for / 4
	SHR	AH, CL			; DH = row / 4
	XCHG	AX, DI			; return as DX
	JMP	SHORT INT_10_4_DONE	; clear latch and return with AH=1
INT_10_4 ENDP
		ENDIF

;
; 77 BYTES HERE / 0 BYTES HERE 5150
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
			IF OEM_FONT EQ 1
;----------------------------------------------------------------------------;
; A more OEM style font
;
	DB	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H	; 00H
	DB	07EH, 081H, 0A5H, 081H, 0BDH, 099H, 081H, 07EH	; 01H
	DB	07EH, 0FFH, 0DBH, 0FFH, 0C3H, 0E7H, 0FFH, 07EH	; 02H
	DB	06CH, 0FEH, 0FEH, 0FEH, 07CH, 038H, 010H, 000H	; 03H
	DB	010H, 038H, 07CH, 0FEH, 07CH, 038H, 010H, 000H	; 04H
	DB	038H, 07CH, 038H, 0FEH, 0FEH, 07CH, 038H, 07CH	; 05H
	DB	010H, 010H, 038H, 07CH, 0FEH, 07CH, 038H, 07CH	; 06H
	DB	000H, 000H, 018H, 03CH, 03CH, 018H, 000H, 000H	; 07H
	DB	0FFH, 0FFH, 0E7H, 0C3H, 0C3H, 0E7H, 0FFH, 0FFH	; 08H
	DB	000H, 03CH, 066H, 042H, 042H, 066H, 03CH, 000H	; 09H
	DB	0FFH, 0C3H, 099H, 0BDH, 0BDH, 099H, 0C3H, 0FFH	; 0AH
	DB	00FH, 007H, 00FH, 07DH, 0CCH, 0CCH, 0CCH, 078H	; 0BH
	DB	03CH, 066H, 066H, 066H, 03CH, 018H, 07EH, 018H	; 0CH
	DB	03FH, 033H, 03FH, 030H, 030H, 070H, 0F0H, 0E0H	; 0DH
	DB	07FH, 063H, 07FH, 063H, 063H, 067H, 0E6H, 0C0H	; 0EH
	DB	099H, 05AH, 03CH, 0E7H, 0E7H, 03CH, 05AH, 099H	; 0FH
	DB	080H, 0E0H, 0F8H, 0FEH, 0F8H, 0E0H, 080H, 000H	; 10H
	DB	002H, 00EH, 03EH, 0FEH, 03EH, 00EH, 002H, 000H	; 11H
	DB	018H, 03CH, 07EH, 018H, 018H, 07EH, 03CH, 018H	; 12H
	DB	066H, 066H, 066H, 066H, 066H, 000H, 066H, 000H	; 13H
	DB	07FH, 0DBH, 0DBH, 07BH, 01BH, 01BH, 01BH, 000H	; 14H
	DB	03EH, 063H, 038H, 06CH, 06CH, 038H, 0CCH, 078H	; 15H
	DB	000H, 000H, 000H, 000H, 07EH, 07EH, 07EH, 000H	; 16H
	DB	018H, 03CH, 07EH, 018H, 07EH, 03CH, 018H, 0FFH	; 17H
	DB	018H, 03CH, 07EH, 018H, 018H, 018H, 018H, 000H	; 18H
	DB	018H, 018H, 018H, 018H, 07EH, 03CH, 018H, 000H	; 19H
	DB	000H, 018H, 00CH, 0FEH, 00CH, 018H, 000H, 000H	; 1AH
	DB	000H, 030H, 060H, 0FEH, 060H, 030H, 000H, 000H	; 1BH
	DB	000H, 000H, 0C0H, 0C0H, 0C0H, 0FEH, 000H, 000H	; 1CH
	DB	000H, 024H, 066H, 0FFH, 066H, 024H, 000H, 000H	; 1DH
	DB	000H, 018H, 03CH, 07EH, 0FFH, 0FFH, 000H, 000H	; 1EH
	DB	000H, 0FFH, 0FFH, 07EH, 03CH, 018H, 000H, 000H	; 1FH
	DB	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H	; 20H  
	DB	030H, 078H, 078H, 030H, 030H, 000H, 030H, 000H	; 21H !
	DB	06CH, 06CH, 06CH, 000H, 000H, 000H, 000H, 000H	; 22H "
	DB	06CH, 06CH, 0FEH, 06CH, 0FEH, 06CH, 06CH, 000H	; 23H #
	DB	030H, 07CH, 0C0H, 078H, 00CH, 0F8H, 030H, 000H	; 24H $
	DB	000H, 0C6H, 0CCH, 018H, 030H, 066H, 0C6H, 000H	; 25H %
	DB	038H, 06CH, 038H, 076H, 0DCH, 0CCH, 076H, 000H	; 26H &
	DB	060H, 060H, 0C0H, 000H, 000H, 000H, 000H, 000H	; 27H '
	DB	018H, 030H, 060H, 060H, 060H, 030H, 018H, 000H	; 28H (
	DB	060H, 030H, 018H, 018H, 018H, 030H, 060H, 000H	; 29H )
	DB	000H, 066H, 03CH, 0FFH, 03CH, 066H, 000H, 000H	; 2AH *
	DB	000H, 030H, 030H, 0FCH, 030H, 030H, 000H, 000H	; 2BH +
	DB	000H, 000H, 000H, 000H, 000H, 030H, 030H, 060H	; 2CH ,
	DB	000H, 000H, 000H, 0FCH, 000H, 000H, 000H, 000H	; 2DH -
	DB	000H, 000H, 000H, 000H, 000H, 030H, 030H, 000H	; 2EH .
	DB	006H, 00CH, 018H, 030H, 060H, 0C0H, 080H, 000H	; 2FH /
	DB	07CH, 0C6H, 0CEH, 0DEH, 0F6H, 0E6H, 07CH, 000H	; 30H 0
	DB	030H, 070H, 030H, 030H, 030H, 030H, 0FCH, 000H	; 31H 1
	DB	078H, 0CCH, 00CH, 038H, 060H, 0CCH, 0FCH, 000H	; 32H 2
	DB	078H, 0CCH, 00CH, 038H, 00CH, 0CCH, 078H, 000H	; 33H 3
	DB	01CH, 03CH, 06CH, 0CCH, 0FEH, 00CH, 01EH, 000H	; 34H 4
	DB	0FCH, 0C0H, 0F8H, 00CH, 00CH, 0CCH, 078H, 000H	; 35H 5
	DB	038H, 060H, 0C0H, 0F8H, 0CCH, 0CCH, 078H, 000H	; 36H 6
	DB	0FCH, 0CCH, 00CH, 018H, 030H, 030H, 030H, 000H	; 37H 7
	DB	078H, 0CCH, 0CCH, 078H, 0CCH, 0CCH, 078H, 000H	; 38H 8
	DB	078H, 0CCH, 0CCH, 07CH, 00CH, 018H, 070H, 000H	; 39H 9
	DB	000H, 030H, 030H, 000H, 000H, 030H, 030H, 000H	; 3AH :
	DB	000H, 030H, 030H, 000H, 000H, 030H, 030H, 060H	; 3BH ;
	DB	018H, 030H, 060H, 0C0H, 060H, 030H, 018H, 000H	; 3CH <
	DB	000H, 000H, 0FCH, 000H, 000H, 0FCH, 000H, 000H	; 3DH =
	DB	060H, 030H, 018H, 00CH, 018H, 030H, 060H, 000H	; 3EH >
	DB	078H, 0CCH, 00CH, 018H, 030H, 000H, 030H, 000H	; 3FH ?
	DB	07CH, 0C6H, 0DEH, 0DEH, 0DEH, 0C0H, 078H, 000H	; 40H @
	DB	030H, 078H, 0CCH, 0CCH, 0FCH, 0CCH, 0CCH, 000H	; 41H A
	DB	0FCH, 066H, 066H, 07CH, 066H, 066H, 0FCH, 000H	; 42H B
	DB	03CH, 066H, 0C0H, 0C0H, 0C0H, 066H, 03CH, 000H	; 43H C
	DB	0F8H, 06CH, 066H, 066H, 066H, 06CH, 0F8H, 000H	; 44H D
	DB	0FEH, 062H, 068H, 078H, 068H, 062H, 0FEH, 000H	; 45H E
	DB	0FEH, 062H, 068H, 078H, 068H, 060H, 0F0H, 000H	; 46H F
	DB	03CH, 066H, 0C0H, 0C0H, 0CEH, 066H, 03EH, 000H	; 47H G
	DB	0CCH, 0CCH, 0CCH, 0FCH, 0CCH, 0CCH, 0CCH, 000H	; 48H H
	DB	078H, 030H, 030H, 030H, 030H, 030H, 078H, 000H	; 49H I
	DB	01EH, 00CH, 00CH, 00CH, 0CCH, 0CCH, 078H, 000H	; 4AH J
	DB	0E6H, 066H, 06CH, 078H, 06CH, 066H, 0E6H, 000H	; 4BH K
	DB	0F0H, 060H, 060H, 060H, 062H, 066H, 0FEH, 000H	; 4CH L
	DB	0C6H, 0EEH, 0FEH, 0FEH, 0D6H, 0C6H, 0C6H, 000H	; 4DH M
	DB	0C6H, 0E6H, 0F6H, 0DEH, 0CEH, 0C6H, 0C6H, 000H	; 4EH N
	DB	038H, 06CH, 0C6H, 0C6H, 0C6H, 06CH, 038H, 000H	; 4FH O
	DB	0FCH, 066H, 066H, 07CH, 060H, 060H, 0F0H, 000H	; 50H P
	DB	078H, 0CCH, 0CCH, 0CCH, 0DCH, 078H, 01CH, 000H	; 51H Q
	DB	0FCH, 066H, 066H, 07CH, 06CH, 066H, 0E6H, 000H	; 52H R
	DB	078H, 0CCH, 0E0H, 070H, 01CH, 0CCH, 078H, 000H	; 53H S
	DB	0FCH, 0B4H, 030H, 030H, 030H, 030H, 078H, 000H	; 54H T
	DB	0CCH, 0CCH, 0CCH, 0CCH, 0CCH, 0CCH, 0FCH, 000H	; 55H U
	DB	0CCH, 0CCH, 0CCH, 0CCH, 0CCH, 078H, 030H, 000H	; 56H V
	DB	0C6H, 0C6H, 0C6H, 0D6H, 0FEH, 0EEH, 0C6H, 000H	; 57H W
	DB	0C6H, 0C6H, 06CH, 038H, 038H, 06CH, 0C6H, 000H	; 58H X
	DB	0CCH, 0CCH, 0CCH, 078H, 030H, 030H, 078H, 000H	; 59H Y
	DB	0FEH, 0C6H, 08CH, 018H, 032H, 066H, 0FEH, 000H	; 5AH Z
	DB	078H, 060H, 060H, 060H, 060H, 060H, 078H, 000H	; 5BH [
	DB	0C0H, 060H, 030H, 018H, 00CH, 006H, 002H, 000H	; 5CH \
	DB	078H, 018H, 018H, 018H, 018H, 018H, 078H, 000H	; 5DH ]
	DB	010H, 038H, 06CH, 0C6H, 000H, 000H, 000H, 000H	; 5EH ^
	DB	000H, 000H, 000H, 000H, 000H, 000H, 000H, 0FFH	; 5FH _
	DB	030H, 030H, 018H, 000H, 000H, 000H, 000H, 000H	; 60H `
	DB	000H, 000H, 078H, 00CH, 07CH, 0CCH, 076H, 000H	; 61H a
	DB	0E0H, 060H, 060H, 07CH, 066H, 066H, 0DCH, 000H	; 62H b
	DB	000H, 000H, 078H, 0CCH, 0C0H, 0CCH, 078H, 000H	; 63H c
	DB	01CH, 00CH, 00CH, 07CH, 0CCH, 0CCH, 076H, 000H	; 64H d
	DB	000H, 000H, 078H, 0CCH, 0FCH, 0C0H, 078H, 000H	; 65H e
	DB	038H, 06CH, 060H, 0F0H, 060H, 060H, 0F0H, 000H	; 66H f
	DB	000H, 000H, 076H, 0CCH, 0CCH, 07CH, 00CH, 0F8H	; 67H g
	DB	0E0H, 060H, 06CH, 076H, 066H, 066H, 0E6H, 000H	; 68H h
	DB	030H, 000H, 070H, 030H, 030H, 030H, 078H, 000H	; 69H i
	DB	00CH, 000H, 00CH, 00CH, 00CH, 0CCH, 0CCH, 078H	; 6AH j
	DB	0E0H, 060H, 066H, 06CH, 078H, 06CH, 0E6H, 000H	; 6BH k
	DB	070H, 030H, 030H, 030H, 030H, 030H, 078H, 000H	; 6CH l
	DB	000H, 000H, 0CCH, 0FEH, 0FEH, 0D6H, 0C6H, 000H	; 6DH m
	DB	000H, 000H, 0F8H, 0CCH, 0CCH, 0CCH, 0CCH, 000H	; 6EH n
	DB	000H, 000H, 078H, 0CCH, 0CCH, 0CCH, 078H, 000H	; 6FH o
	DB	000H, 000H, 0DCH, 066H, 066H, 07CH, 060H, 0F0H	; 70H p
	DB	000H, 000H, 076H, 0CCH, 0CCH, 07CH, 00CH, 01EH	; 71H q
	DB	000H, 000H, 0DCH, 076H, 066H, 060H, 0F0H, 000H	; 72H r
	DB	000H, 000H, 07CH, 0C0H, 078H, 00CH, 0F8H, 000H	; 73H s
	DB	010H, 030H, 07CH, 030H, 030H, 034H, 018H, 000H	; 74H t
	DB	000H, 000H, 0CCH, 0CCH, 0CCH, 0CCH, 076H, 000H	; 75H u
	DB	000H, 000H, 0CCH, 0CCH, 0CCH, 078H, 030H, 000H	; 76H v
	DB	000H, 000H, 0C6H, 0D6H, 0FEH, 0FEH, 06CH, 000H	; 77H w
	DB	000H, 000H, 0C6H, 06CH, 038H, 06CH, 0C6H, 000H	; 78H x
	DB	000H, 000H, 0CCH, 0CCH, 0CCH, 07CH, 00CH, 0F8H	; 79H y
	DB	000H, 000H, 0FCH, 098H, 030H, 064H, 0FCH, 000H	; 7AH z
	DB	01CH, 030H, 030H, 0E0H, 030H, 030H, 01CH, 000H	; 7BH {
	DB	018H, 018H, 018H, 000H, 018H, 018H, 018H, 000H	; 7CH |
	DB	0E0H, 030H, 030H, 01CH, 030H, 030H, 0E0H, 000H	; 7DH }
	DB	076H, 0DCH, 000H, 000H, 000H, 000H, 000H, 000H	; 7EH ~
	DB	000H, 010H, 038H, 06CH, 0C6H, 0C6H, 0FEH, 000H	; 7FH
			ELSE
;----------------------------------------------------------------------------;
; A more clone style font
;
	DB	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H	; 00H
	DB	07EH, 081H, 0A5H, 081H, 0BDH, 099H, 081H, 07EH	; 01H
	DB	07EH, 0DBH, 0FFH, 0FFH, 0C3H, 0E7H, 07EH, 000H	; 02H
	DB	036H, 07FH, 07FH, 07FH, 03EH, 01CH, 008H, 000H	; 03H
	DB	008H, 01CH, 03EH, 07FH, 03EH, 01CH, 008H, 000H	; 04H
	DB	018H, 03CH, 018H, 066H, 0FFH, 066H, 018H, 03CH	; 05H
	DB	008H, 01CH, 03EH, 07FH, 07FH, 03EH, 008H, 01CH	; 06H
	DB	000H, 000H, 018H, 03CH, 03CH, 018H, 000H, 000H	; 07H
	DB	0FFH, 0FFH, 0E7H, 0C3H, 0C3H, 0E7H, 0FFH, 0FFH	; 08H
	DB	000H, 03CH, 066H, 042H, 042H, 066H, 03CH, 000H	; 09H
	DB	0FFH, 0C3H, 099H, 0BDH, 0BDH, 099H, 0C3H, 0FFH	; 0AH
	DB	03FH, 00DH, 01CH, 03EH, 063H, 063H, 03EH, 000H	; 0BH
	DB	03EH, 063H, 063H, 03EH, 01CH, 07FH, 01CH, 000H	; 0CH
	DB	00EH, 00FH, 00DH, 00DH, 01CH, 07FH, 01CH, 000H	; 0DH
	DB	00FH, 03BH, 037H, 03BH, 033H, 037H, 077H, 070H	; 0EH
	DB	018H, 0DBH, 03CH, 0E7H, 03CH, 0DBH, 018H, 000H	; 0FH
	DB	060H, 078H, 07EH, 07FH, 07EH, 078H, 060H, 000H	; 10H
	DB	003H, 00FH, 03FH, 07FH, 03FH, 00FH, 003H, 000H	; 11H
	DB	018H, 03CH, 07EH, 018H, 018H, 07EH, 03CH, 018H	; 12H
	DB	066H, 066H, 066H, 066H, 066H, 000H, 066H, 000H	; 13H
	DB	03FH, 06DH, 06DH, 03DH, 00DH, 00DH, 00DH, 000H	; 14H
	DB	03FH, 070H, 03EH, 063H, 063H, 03EH, 007H, 07EH	; 15H
	DB	000H, 000H, 000H, 000H, 0FFH, 0FFH, 0FFH, 000H	; 16H
	DB	03CH, 07EH, 018H, 018H, 07EH, 03CH, 018H, 07EH	; 17H
	DB	018H, 03CH, 07EH, 018H, 018H, 018H, 018H, 000H	; 18H
	DB	018H, 018H, 018H, 018H, 07EH, 03CH, 018H, 000H	; 19H
	DB	018H, 00CH, 006H, 07FH, 006H, 00CH, 018H, 000H	; 1AH
	DB	00CH, 018H, 030H, 07FH, 030H, 018H, 00CH, 000H	; 1BH
	DB	000H, 000H, 000H, 060H, 060H, 07FH, 000H, 000H	; 1CH
	DB	000H, 024H, 066H, 0FFH, 066H, 024H, 000H, 000H	; 1DH
	DB	008H, 01CH, 01CH, 03EH, 03EH, 07FH, 07FH, 000H	; 1EH
	DB	07FH, 07FH, 03EH, 03EH, 01CH, 01CH, 008H, 000H	; 1FH
	DB	000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H	; 20H  
	DB	018H, 018H, 018H, 018H, 018H, 000H, 018H, 000H	; 21H !
	DB	033H, 066H, 0CCH, 000H, 000H, 000H, 000H, 000H	; 22H "
	DB	036H, 036H, 07FH, 036H, 036H, 07FH, 036H, 036H	; 23H #
	DB	018H, 07EH, 058H, 038H, 01CH, 01AH, 07EH, 018H	; 24H $
	DB	0E3H, 0A6H, 0ECH, 018H, 037H, 065H, 0C7H, 000H	; 25H %
	DB	03CH, 066H, 03CH, 038H, 06DH, 066H, 03DH, 000H	; 26H &
	DB	006H, 00CH, 018H, 000H, 000H, 000H, 000H, 000H	; 27H '
	DB	01CH, 030H, 060H, 060H, 060H, 030H, 01CH, 000H	; 28H (
	DB	038H, 00CH, 006H, 006H, 006H, 00CH, 038H, 000H	; 29H )
	DB	063H, 036H, 01CH, 07FH, 01CH, 036H, 063H, 000H	; 2AH *
	DB	018H, 018H, 018H, 07EH, 018H, 018H, 018H, 000H	; 2BH +
	DB	000H, 000H, 000H, 000H, 000H, 018H, 018H, 030H	; 2CH ,
	DB	000H, 000H, 000H, 07EH, 000H, 000H, 000H, 000H	; 2DH -
	DB	000H, 000H, 000H, 000H, 000H, 018H, 018H, 000H	; 2EH .
	DB	002H, 006H, 00CH, 018H, 030H, 060H, 040H, 000H	; 2FH /
	DB	03EH, 063H, 063H, 06BH, 063H, 063H, 03EH, 000H	; 30H 0
	DB	01CH, 03CH, 00CH, 00CH, 00CH, 00CH, 00CH, 000H	; 31H 1
	DB	03EH, 063H, 003H, 00EH, 038H, 060H, 07FH, 000H	; 32H 2
	DB	07CH, 006H, 006H, 03CH, 006H, 006H, 07CH, 000H	; 33H 3
	DB	00EH, 01EH, 036H, 066H, 07FH, 006H, 006H, 000H	; 34H 4
	DB	07EH, 060H, 07CH, 006H, 006H, 006H, 07CH, 000H	; 35H 5
	DB	01EH, 030H, 060H, 07EH, 063H, 063H, 03EH, 000H	; 36H 6
	DB	07EH, 066H, 00CH, 018H, 030H, 030H, 030H, 000H	; 37H 7
	DB	03EH, 063H, 036H, 01CH, 036H, 063H, 03EH, 000H	; 38H 8
	DB	03EH, 063H, 063H, 03FH, 003H, 006H, 07CH, 000H	; 39H 9
	DB	000H, 000H, 018H, 018H, 000H, 018H, 018H, 000H	; 3AH :
	DB	000H, 000H, 018H, 018H, 000H, 018H, 018H, 030H	; 3BH ;
	DB	00CH, 018H, 030H, 060H, 030H, 018H, 00CH, 000H	; 3CH <
	DB	000H, 000H, 07EH, 000H, 07EH, 000H, 000H, 000H	; 3DH =
	DB	030H, 018H, 00CH, 006H, 00CH, 018H, 030H, 000H	; 3EH >
	DB	03EH, 063H, 006H, 00CH, 00CH, 000H, 00CH, 000H	; 3FH ?
	DB	03EH, 063H, 06FH, 069H, 06FH, 060H, 03FH, 000H	; 40H @
	DB	03CH, 066H, 066H, 07EH, 066H, 066H, 066H, 000H	; 41H A
	DB	07EH, 063H, 063H, 07EH, 063H, 063H, 07EH, 000H	; 42H B
	DB	01EH, 033H, 060H, 060H, 060H, 033H, 01EH, 000H	; 43H C
	DB	07CH, 066H, 063H, 063H, 063H, 066H, 07CH, 000H	; 44H D
	DB	07EH, 060H, 060H, 07CH, 060H, 060H, 07EH, 000H	; 45H E
	DB	07EH, 060H, 060H, 07CH, 060H, 060H, 060H, 000H	; 46H F
	DB	01EH, 033H, 063H, 060H, 067H, 033H, 01EH, 000H	; 47H G
	DB	063H, 063H, 063H, 07FH, 063H, 063H, 063H, 000H	; 48H H
	DB	03CH, 018H, 018H, 018H, 018H, 018H, 03CH, 000H	; 49H I
	DB	006H, 006H, 006H, 006H, 066H, 066H, 03CH, 000H	; 4AH J
	DB	063H, 066H, 06CH, 078H, 06CH, 066H, 063H, 000H	; 4BH K
	DB	030H, 030H, 030H, 030H, 030H, 030H, 03FH, 000H	; 4CH L
	DB	063H, 077H, 07FH, 06BH, 063H, 063H, 063H, 000H	; 4DH M
	DB	063H, 073H, 07BH, 06FH, 067H, 063H, 063H, 000H	; 4EH N
	DB	03EH, 063H, 063H, 063H, 063H, 063H, 03EH, 000H	; 4FH O
	DB	07EH, 063H, 063H, 07EH, 060H, 060H, 060H, 000H	; 50H P
	DB	03EH, 063H, 063H, 063H, 07BH, 06EH, 03CH, 007H	; 51H Q
	DB	07EH, 063H, 063H, 07EH, 06CH, 066H, 063H, 000H	; 52H R
	DB	03EH, 063H, 030H, 01CH, 006H, 063H, 03EH, 000H	; 53H S
	DB	07EH, 018H, 018H, 018H, 018H, 018H, 018H, 000H	; 54H T
	DB	063H, 063H, 063H, 063H, 063H, 063H, 03EH, 000H	; 55H U
	DB	063H, 063H, 063H, 063H, 036H, 01CH, 008H, 000H	; 56H V
	DB	063H, 063H, 063H, 06BH, 06BH, 07FH, 036H, 000H	; 57H W
	DB	063H, 063H, 036H, 01CH, 036H, 063H, 063H, 000H	; 58H X
	DB	063H, 063H, 063H, 03EH, 00CH, 00CH, 00CH, 000H	; 59H Y
	DB	07FH, 006H, 00CH, 018H, 030H, 060H, 07FH, 000H	; 5AH Z
	DB	03EH, 030H, 030H, 030H, 030H, 030H, 03EH, 000H	; 5BH [
	DB	040H, 060H, 030H, 018H, 00CH, 006H, 002H, 000H	; 5CH \
	DB	03EH, 006H, 006H, 006H, 006H, 006H, 03EH, 000H	; 5DH ]
	DB	01CH, 036H, 063H, 000H, 000H, 000H, 000H, 000H	; 5EH ^
	DB	000H, 000H, 000H, 000H, 000H, 000H, 000H, 0FFH	; 5FH _
	DB	030H, 018H, 00CH, 000H, 000H, 000H, 000H, 000H	; 60H `
	DB	000H, 000H, 03CH, 006H, 03EH, 066H, 03FH, 000H	; 61H a
	DB	060H, 060H, 07CH, 066H, 066H, 066H, 07CH, 000H	; 62H b
	DB	000H, 000H, 03EH, 063H, 060H, 060H, 03FH, 000H	; 63H c
	DB	006H, 006H, 03EH, 066H, 066H, 066H, 03EH, 000H	; 64H d
	DB	000H, 000H, 03CH, 066H, 07CH, 060H, 03EH, 000H	; 65H e
	DB	01EH, 030H, 030H, 07CH, 030H, 030H, 030H, 000H	; 66H f
	DB	000H, 000H, 03FH, 063H, 063H, 03FH, 003H, 07EH	; 67H g
	DB	060H, 060H, 06CH, 076H, 066H, 066H, 066H, 000H	; 68H h
	DB	018H, 000H, 038H, 018H, 018H, 018H, 018H, 000H	; 69H i
	DB	006H, 000H, 006H, 006H, 006H, 006H, 066H, 03CH	; 6AH j
	DB	060H, 060H, 066H, 06CH, 078H, 06CH, 066H, 000H	; 6BH k
	DB	018H, 018H, 018H, 018H, 018H, 018H, 00CH, 000H	; 6CH l
	DB	000H, 000H, 076H, 07FH, 06BH, 06BH, 063H, 000H	; 6DH m
	DB	000H, 000H, 06CH, 076H, 066H, 066H, 066H, 000H	; 6EH n
	DB	000H, 000H, 03EH, 063H, 063H, 063H, 03EH, 000H	; 6FH o
	DB	000H, 000H, 07CH, 066H, 066H, 07CH, 060H, 060H	; 70H p
	DB	000H, 000H, 03EH, 066H, 066H, 03EH, 006H, 006H	; 71H q
	DB	000H, 000H, 036H, 03BH, 030H, 030H, 030H, 000H	; 72H r
	DB	000H, 000H, 03EH, 070H, 03CH, 00EH, 07CH, 000H	; 73H s
	DB	018H, 018H, 07EH, 018H, 018H, 018H, 00EH, 000H	; 74H t
	DB	000H, 000H, 066H, 066H, 066H, 066H, 03BH, 000H	; 75H u
	DB	000H, 000H, 066H, 066H, 066H, 03CH, 018H, 000H	; 76H v
	DB	000H, 000H, 063H, 063H, 06BH, 07FH, 036H, 000H	; 77H w
	DB	000H, 000H, 063H, 036H, 01CH, 036H, 063H, 000H	; 78H x
	DB	000H, 000H, 066H, 066H, 066H, 03EH, 006H, 07CH	; 79H y
	DB	000H, 000H, 07EH, 00CH, 018H, 030H, 07EH, 000H	; 7AH z
	DB	00EH, 018H, 018H, 078H, 018H, 018H, 00EH, 000H	; 7BH {
	DB	018H, 018H, 018H, 000H, 018H, 018H, 018H, 000H	; 7CH |
	DB	070H, 018H, 018H, 00EH, 018H, 018H, 070H, 000H	; 7DH }
	DB	03BH, 06EH, 000H, 000H, 000H, 000H, 000H, 000H	; 7EH ~
	DB	018H, 03CH, 066H, 0C3H, 0C3H, 0FFH, 000H, 000H	; 7FH
			ENDIF

;----------------------------------------------------------------------------;
; INT 1A - System and "Real Time" Clock BIOS Services
;----------------------------------------------------------------------------;
; INT 1A,0   Read system clock counter
; INT 1A,1   Set system clock counter
;----------------------------------------------------------------------------;
		ORG 0FE6EH
INT_1A PROC
		ASSUME DS:_BDA
	STI						; enable interrupts
	SUB	AH, 1 				; is function 0 or 1?
	JA	INT_1A_EXIT 			; if not, exit
	PUSH	DS
	PUSH	SI
	MOV	SI, SEG _BDA 			; get BDA segment
	MOV	DS, SI 				; DS = BDA
	MOV	SI, OFFSET TIMER			; SI = BIOS Timer
	CLI 						; disable interrupts
	JZ	INT_1A_SET 				; AH = 1, jump to Set clock
							; AH = 0, fall through to Read

;----------------------------------------------------------------------------;
; INT 1A,0   Read system clock counter
;----------------------------------------------------------------------------;
; Output:
;	AL = midnight flag, 1 if 24 hours passed since reset
;	CX = high order word of tick count
;	DX = low order word of tick count
;----------------------------------------------------------------------------;
INT_1A_READ PROC
	CLD						; string direction forward
	LODSW 					; AX = low word of timer
	XCHG	AX, DX
	LODSW 					; AX = high word of timer
	XCHG	AX, CX
	XOR	AX, AX				; reset midnight flag to 0
	XCHG	AL, [SI]				; AL = BDA flag, BDA = 0
INT_1A_DONE:
	;STI 						; re-enable interrupts
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
	MOV	[SI].LW, DX				; set low word ticks (seconds)
	MOV	[SI].HW, CX				; set high word ticks (hours)
	MOV	[SI].OF, AH				; reset midnight counter (0)
	JMP	SHORT INT_1A_DONE
INT_1A_SET ENDP

INT_1A ENDP

INT_08_PROC PROC
;----------------------------------------------------------------------------;
; INT 8 - Floppy Motor shutoff has elapsed - shut off motor
;----------------------------------------------------------------------------;
INT_08_MOTOR_OFF:
	MOV	AL, NOT MASK FMOT			; BDA motor off on all drives
	AND	FD_MOTOR_ST, AL			; write to BDA
	XOR	AL, NOT MASK FDSEL		; FDC motor off on all drives
	MOV	DX, FDC_CTRL 			; FD control port
	OUT	DX, AL 				; write to controller
	JMP	SHORT INT_08_INT_1C

;
; 0 BYTES HERE
;
BYTES_HERE	INT_08

;----------------------------------------------------------------------------;
; INT 8 - Timer
;----------------------------------------------------------------------------;
; - Run 18.2 times per second by PIT Timer
; - f = 1193182 / 10000H
; - Increment 32 bit counter, overflows at 24 hours + 9.67 sec
;	( 3600s/h - 65,536t / ( 1,193,182t/s / 65,536t ) ) * 24h = ~9.67s
; - Decrement floppy disk motor timeout counter
;  	  if reaches 0, turns off motor
; - only take jumps on special cases
;
; IMPORTANT NOTE: ROM BASIC's INT 1CH handler clobbers DX, so DX
; MUST be call-preserved here.
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
	CWD						; DX = 0

;----------------------------------------------------------------------------;
; Increment Timer
;
INT_08_TICK_TIMER:				; Advance the time ticker
	MOV	DI, OFFSET TIMER 			; Low timer at BDA 0040:006C
	ADD	[DI].LW, 1				; increment low word
	ADC	[DI].HW, DX				; carry into high word
	CMP	[DI].HW, 24 			; rolled over to next day?
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
	MOV	AL, EOI 				; End of Interrupt OCW
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
	CMP	BYTE PTR [DI].LW, 176 		; has day rolled over?
	JB	INT_08_FD_MOTOR			; if not, handle FD motor timeout

;----------------------------------------------------------------------------;
; Timer has rolled over 24 hours - reset counters and increment midnight
; http://www.ctyme.com/intr/rb-2271.htm
; http://www.phatcode.net/res/246/files/pctim003.txt
;
INT_08_RESET:
	MOV	[DI].LW, DX				; TIMER low word = 0
	MOV	[DI].HW, DX				; TIMER high word = 0
	INC	[DI].OF				; increment TIMER midnight counter
	JMP	INT_08_FD_MOTOR			; continue and check motor

INT_08 ENDP
INT_08_PROC ENDP

;
; 3 BYTES HERE
;
BYTES_HERE	VECTOR_TABLE

;----------------------------------------------------------------------------;
; Interrupt Vector Table - These fill the IVT prior to bootstrap
;----------------------------------------------------------------------------;
; Each ISR is found at the compatibility offset described here:
; https://www.intel.com/content/dam/doc/reference-guide/efi-compatibility-support-module-specification-v097.pdf
;----------------------------------------------------------------------------;
		ORG 0FEE3H
VECTOR_TABLE PROC
	DW  OFFSET INT_IRQ 		; INT 00
	DW  OFFSET INT_IRQ 		; INT 01
	DW  OFFSET INT_02 		; INT 02	NMI
	DW  OFFSET INT_IRQ 		; INT 03
	DW  OFFSET INT_IRQ 		; INT 04
	DW  OFFSET INT_05 		; INT 05	Print Screen
	DW  OFFSET INT_IRQ 		; INT 06
	DW  OFFSET INT_IRQ 		; INT 07

;----------------------------------------------------------------------------;
; Compatibility fixed ORG for INT 08 - 1Eh
;
		ORG 0FEF3H
	DW  OFFSET INT_08 		; INT 08	IRQ0 System timer
	DW  OFFSET INT_09_POST		; INT 09	IRQ1 Keyboard IRQ (during POST)
	DW  OFFSET INT_IRQ		; INT 0A	IRQ2 Reserved
	DW  OFFSET INT_IRQ		; INT 0B	IRQ3 COM2
	DW  OFFSET INT_IRQ		; INT 0C	IRQ4 COM1
	DW  OFFSET INT_IRQ		; INT 0D	IRQ5 XT FDC
	DW  OFFSET INT_0E			; INT 0E	IRQ6 Floppy Controller
	DW  OFFSET INT_IRQ		; INT 0F	IRQ7 LPT
	DW  OFFSET INT_10			; INT 10	Video
	DW  OFFSET INT_11			; INT 11	Equipment Check
	DW  OFFSET INT_12			; INT 12	Memory Size
	DW  OFFSET INT_13			; INT 13	Floppy Disk
	DW  OFFSET INT_14			; INT 14	Serial Port
	DW  OFFSET INT_15			; INT 15	System Services
	DW  OFFSET INT_16			; INT 16	Keyboard Services
	DW  OFFSET INT_17			; INT 17	Printer
	DW  OFFSET INT_18 		; INT 18	Unbootable/ROM BASIC
			IF FDC_ENABLE EQ 1
	DW  OFFSET INT_19			; INT 19	Bootstrap
			ELSE
	DW  OFFSET INT_RET		; INT 19	No floppy bootstrap
			ENDIF
	DW  OFFSET INT_1A			; INT 1A	Time of day
	DW  OFFSET INT_RET 		; INT 1B	Ctrl Brk
	DW  OFFSET INT_RET 		; INT 1C	Timer Tick
	DW  OFFSET INT_1D 		; INT 1D	CRTC param table
	DW  OFFSET INT_1E 		; INT 1E	Floppy param table
L_VECTOR_TABLE = ($-VECTOR_TABLE)/2	; number of vectors 1Fh (31)
	DW  0 				; INT 1F	8x8 (CP 128-255) custom
						;		 video font table (0000:0000)
VECTOR_TABLE ENDP

;----------------------------------------------------------------------------;
; INT_IRQ - Handle placeholder hardware interrupts
;----------------------------------------------------------------------------;
; ISR for any hardware interrupts that have yet to be vectored.
; Acknowledge interrupt, mask the active one and write last HW interrupt to BDA.
;
; Output:
;	INT_LAST = last interrupt or 0FFh if non-hardware/unknown interrupt
;----------------------------------------------------------------------------;
		ORG 0FF23H
INT_IRQ PROC
			ASSUME DS:_BDA_ABS
	PUSH	AX
	PUSH	DS				; save DS
	MOV	AL, OCW3 <,,,,11b> 	; AL = OCW3 Read ISR reg on next pulse
	OUT	INT_P0, AL			; write to PIC A0 (20h)
	XOR	AX, AX			; AH = 0, delay for PIC at least 1 clock pulse
	MOV	DS, AX			; set DS to BDA_ABS (segment 0000h)
	IN	AL, INT_P0			; get current In-Service Register (ISR)
	DEC	AX				; if ISR is zero there is no active hardware int
	JL	INT_IRQ_DONE		; if no active int, exit with INT_LAST = FFh
	INC	AX				; otherwise INT_LAST = active interrupt level
	MOV	AH, AL 			; restore ISR and save to AH
	IN	AL, INT_IMR			; get current Interrupt Mask Register (IMR)
	OR	AL, AH 			; mask active interrupt
	OUT	INT_IMR, AL			; write new IMR to PIC A1 (21h)
	MOV	AL, EOI 			; AL = OCW2 End of Interrupt
	OUT	INT_P0, AL			; write EOI to PIC A0 (20h)
INT_IRQ_DONE:
	MOV	INT_LAST_ABS, AH	 	; save last interrupt to BDA
	POP	DS
	POP	AX
	IRET
			ASSUME DS:NOTHING
INT_IRQ ENDP

;----------------------------------------------------------------------------;
; POST Video Adapter Type Strings (2 of 2)
; 11 bytes
;
				IF POST_VIDEO_TYPE EQ 1
POST_VIDEO		DB	'Video', 0
				ENDIF
POST_NONE		DB	'None', 0	; must be contiguous to POST_VIDEO

;
; 2 BYTES HERE
;
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
	PUSHX	AX, DI, ES				; preserve caller registers
	MOV	DI, SEG _DOS_DAT
	MOV	ES, DI				; ES = seg 50H
	XOR	DI, DI				; DI = PTRSCN_ST (offset 00H)
	MOV	AL, 1					; print status = 1 (in progress)
	SCASB						; is in progress already?
	JZ	INT_05_EXIT				; if so, exit
	STI						; Interrupts should be okay now
	DEC	DI					; undo earlier SCASB increment
	STOSB						; update status to 1
	PUSHX	BX, CX, DX				; preserve working registers
	MOV	AH, 0FH				; get video state (columns)
	INT	10H					; AH = screen columns, BH = page
	MOV	BL, AH				; BL = screen columns
	DEC	BX					; fix 0 index
	MOV	AH, 3					; get cursor position
	INT	10H					; DH = cursor row, DL = cursor column
	PUSH	DX					; save starting cursor position
	CALL	LPT_CRLF				; start print head on new line
	JC	INT_05_DONE				; exit if print error
	CWD						; start position at row 0, col 0
INT_05_LOOP_1:
	MOV	AH, 2					; set cursor position
	INT	10H					; set cursor to DH=row, DL=col
	MOV	AH, 8					; get char/attr at current position
	INT	10H					; AL = char at current position
	CALL	LPT_CHAR				; print char in AL
	JC	INT_05_DONE				; exit if print error
	CMP	BL, DL				; end of screen cols?
	JNE	INT_05_NEXT_COL			; jump if not
	MOV	DL, -1				; else move to first col and next row
	CALL	LPT_CRLF				; CR and LF to PRN
	JC	INT_05_DONE				; exit if print error
INT_05_NEXT_COL:
	INC	DX					; move to next column (and maybe row)
	CMP	DH, VID_DEF_ROWS+1		; end of screen rows?
	JNE	INT_05_LOOP_1			; loop while not last row, CF=0 when done
INT_05_DONE:
	SBB	AL, AL				; print status: AL = 0 if NC, AL = -1 if CF
	DEC	DI					; undo earlier STOSB increment
	STOSB						; update BDA status
	POP	DX					; restore starting cursor position
	MOV	AH, 2					; set cursor position in DH/DL
	INT	10H
	POPX	DX, CX, BX
INT_05_EXIT:
	POPX	ES, DI, AX
	IRET

;----------------------------------------------------------------------------;
; LPT_CRLF - Write CR and LF to PRN
;----------------------------------------------------------------------------;
LPT_CRLF PROC
	MOV	AL, CR
	CALL	LPT_CHAR
	JC	LPT_CHAR_EXIT			; exit if print error

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
;	CF = 1 (CY) if timeout
;
; AL clobbered if null
;----------------------------------------------------------------------------;
LPT_CHAR PROC
	PUSH	DX
	MOV	AH, 0					; Print Character function
	CWD						; DX = printer 0 (PRN)
	TEST	AL, AL				; was input char a null?
	JNZ	LPT_CHAR_OUT			; jump if not
	MOV	AL, ' '				; if so, use a space
LPT_CHAR_OUT:
	INT	17H					; Print AL to PRN0
	SHR	AH, 1					; CF if timeout
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
;	DI = any non-zero value
; Output:
;	ZF = 0 if no FPU, ZF = 1 if present
;
; Clobbers: BX, DI
;
; Sources:
;   https://retrocomputing.stackexchange.com/questions/16529/detecting-the-external-x87-fpu
;   Intel(R) App Note AP-485 "Intel(R) Processor Identification and the CPUID Instruction"
;----------------------------------------------------------------------------;
HAS_FPU PROC
	XCHG	AX, DI			; save AX
	FNINIT 				; reset FPU, no wait

;----------------------------------------------------------------------------;
; Test Status Word
;
FPU_TEST_SW:
	PUSH	AX 				; init temp word to non-zero
	MOV	BX, SP	 		; use stack memory
	FNSTSW WORD PTR SS:[BX]		; store status word
	NOP					; delay to allow FPU to complete
	POP	AX 				; AX = control word if FNSTCW executed
	TEST	AL, AL 			; check exception flags
	JNZ	FPU_TEST_DONE		; if flags = 00, FPU is present

;----------------------------------------------------------------------------;
; Test Control Word
;
FPU_TEST_CW:
	PUSH	AX
	FNSTCW WORD PTR SS:[BX]		; store control word
	NOP					; delay to allow FPU to complete
	POP	AX 				; AX = control word
	XOR	AX, 0103FH 			; isolate interesting status flags
	AND	AX, 03FH 			; check for 8087 "signature"
						; ZF = 0 if no FPU
FPU_TEST_DONE:
	XCHG	AX, DI			; restore AX
	RET
HAS_FPU ENDP

;
; 0 BYTES HERE
;
BYTES_HERE	VER

;----------------------------------------------------------------------------;
; Version and Build Strings
;----------------------------------------------------------------------------;
		ORG	0FFE0H
VER 	DB	'Ver: '
	DB	VER_NUM
	DB	'-'				; Show CPU type and
	DB	CPU_TYPE			; architecture target
	DB	ARCH_TYPE
			IF ARCH_SUB_TYPE NE 0
	DB	ARCH_SUB_TYPE		; add optional ARCH sub-identifier
			ENDIF
	DB	' '				; space before date
	DB	0

;
; 0 BYTES HERE
;
BYTES_HERE	POWER_ON

BIOS		ENDS

;============================================================================;
;
;				* * *    END OF BIOS   * * *
;
;============================================================================;

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
; # sublime: tab_completion false; auto_complete false; tab_size 6
