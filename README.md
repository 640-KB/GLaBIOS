# GLaBIOS
## (General Libraries and Basic Input Output System)
A modern, scratch-built, open-source alternative BIOS for vintage PC, XT, 8088 Clone or Turbo PCs.

Copyright (c) 2022, 640KB and contributors

## Preview pre-release available!

[Ver 0.0.11 ROMs now available for testing!](https://github.com/640-KB/GLaBIOS/releases)

## License

- GNU General Public License v3.0. See [LICENSE](LICENSE).

## Features

- A complete "100% PC Compatible" BIOS for retro/vintage PC, XT, 8088 Clone or Turbo PCs.
- Support for 5150, 5160, Turbo and compatible clone hardware.
- Performance-optmized CGA/MDA text and graphics routines. Multiple levels of CGA snow removal (configurable at build-time).
- Accurate PIT-based I/O timing. Better stability at faster clock speeds and increased speed on slower PCs.
- NEC V20 enhanced instruction support (enabled at build-time).
- POST test screen colors support easily customized themes (build-time).
- Beeps pitched correctly at A<sub>5</sub> (880Hz), &frac14; second long regardless of clock speed. (Silly? Maybe, but who wants a flat beep?)

## FAQ

### Why another 8088 PC BIOS in 2022?

Because learning.  I've always wanted to know what actually happens inside the big gray box
and how everything actually works on a PC. Like an old car, radio or TV it's actually possible
for a hobbyist to learn all of the inner workings and be able to repair or build.

### Where did the name originate?

If you aren't familiar with the reference, ask a gamer.

### Project Goals

There are several other excellent BIOS projects out there each with it's own design goals and use cases. These are the goals for this one:

1. Learning
2. A fully open-source PC BIOS, free of outside proprietary or copyrighted code
3. Feature-complete with full support for original vintage hardware
4. Fit in an 8K ROM to drop in to any original PC or clone

### So where is the source code?

It will be released soon, once it is stable enough for testing.

### Screenshots

VGA with 8087 FPU:

![Screenshot VGA 07-29-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.11_vga_1.png)

EGA with V20:

![Screenshot VGA 07-29-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.11_ega_1.png)

CGA:

![Screenshot CGA 07-29-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.11_cga_2.png)

MDA with example POST error:

![Screenshot MDA 07-29-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.11_mda_1.png)

1-2-3 ver 1A

![Screenshot 123 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_gb_123_1.pngg)

Flight Simulator 1.0

![Screenshot FS1 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_gb_fs1_1.png)

## STATUS

### TODO:

| Item	| Complete | TODO/Notes |
| ----------- | ----------- | ----------- |
| INT 09H Keyboard Decoding     | 90% | Ctrl-NumLock (pause), cleanup |
| INT 10H Video for CGA / MDA   | 90%  | Functions AH=8,9,A in CGA graphics modes 4-6 |
| Fixed ORGs for INT vectors    | 95%  | Only INT_0E (needs INT 13h refactoring) |
| POST tests for all ICs        |     | Evaluate necessity of each vs code size to do it |
| RAM / Parity / NMI handling   |     |	Test on real hardware. Provide additional output for offending memory |

## BUILD NOTES:

### Assembler Version

Built using MASM 5.0. MASM and it's syntax has been what I have used and most familiar with in assembly programming. It also provides some sense of historical authenticity _[citation needed]_.

### Code Formatting
- Tab Size: 6 spaces. Indented with TAB characters.

### Code style:
GLaBIOS uses all UPPERCASE mnemonics because 1) it was the way I originally
learned assembly language 2) it's what's used in MASM 5 documentation
and manuals 3) it would have been an accepted practice in the era in when 
PC BIOS clones were written.

### Build Process:

1. `MASM GLABIOS;`
2. `LINK GLABIOS;`  Will create GLABIOS.EXE.
3. Run `GLA2ROM GLABIOS` to convert to an 8 KiB ROM file.

OR

3. Convert EXE manually by removing the EXE header (the first 512 bytes of the EXE file) and extracting the last 8 KiB
4. Calculate 8-bit checksum byte and insert into relative file offset `1FFF` in GLABIOS.ROM.

### Testing

Hampa Hug's excellent [PCE/ibmpc emulator](http://hampa.ch/pce/pce-ibmpc.html) works very well for build testing and debugging.  This provides a near-perfect hardware-accurate emulation of a PC with inspection of ICs, memory and code stepping.  [86Box](http://86box.net/) and [PCem](http://pcem-emulator.co.uk/index.html) also work very well.

### Real Hardware Deployment

[Minuszerodegrees (-0°)](http://www.minuszerodegrees.net/) has a lot of information about [original ROM types](http://minuszerodegrees.net/rom/rom.htm) and "modern" equivalents. I found using [Winbond W27E257](http://www.minuszerodegrees.net/rom/misc/Winbond%20W27E257%20as%2027C256%20replacement.htm) EEPROMs worked very well since it could be electrically erased and re-written quickly.  Since these are 32K EEPROMS, the image will need to be written 4 times sequentially.  I use a TL866 II Plus to write the EEPROMs.

## References and Credits:

- https://stanislavs.org/helppc/
- https://sites.google.com/site/pcdosretro/
- http://www.minuszerodegrees.net/
- https://www.felixcloutier.com/x86/

- Font bitmaps by "VileR", (CC BY-SA 4.0)
	https://int10h.org/oldschool-pc-fonts/readme/#legal_stuff
	
Many more references in inline comments.

### Further Credits to:

- Code Golf (CGCC) (https://codegolf.stackexchange.com/) community on Stack Exchange for helping me become a better ASM programmer.
- Hampa Hug for the excellent PCE software (http://www.hampa.ch/pce/pce-ibmpc.html) that helped make development and debugging much easier.
- Dave Nault, my partner in crime for 2 semesters of college assembly language programming classes back in the day. Wherever you are buddy, hope you're doing well!
