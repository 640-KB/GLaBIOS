# GLaBIOS
## (General Libraries and Basic Input Output System)
A modern, scratch-built, open-source alternative BIOS for 8088 or Turbo PCs.

Copyright (c) 2022, 640KB and contributors

## Preview pre-release available!

[Ver 0.0.10 ROMs now available for testing](https://github.com/640-KB/GLaBIOS/releases)

## License

- GNU General Public License v3.0. See [LICENSE](LICENSE).

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

### Features and build-time options

- Support for Turbo, 5160, 5150 and compatible clone hardware.
- POST test screen is Color "theme-able" (build-time)
- Performance-optmized CGA/MDA text and graphics routines. Multiple levels of CGA snow removal (configurable at build-time).
- Accurate PIT-based I/O timing. Better stability at faster clock speeds and increased speed on slower PCs.
- Support for NEC V20 instructions (enabled at build-time). Performance improvement is negligible but uses them just because.
- Beeps pitched correctly at A<sub>5</sub> (880Hz), &frac14; second long regardless of clock speed. Alternating error beeps are perfect fourth apart. (Is this silly? Maybe, but who wants a flat beep?)

### So where is the source code?

It will be released soon, once it is stable enough for testing.

### Screenshots

EGA:

![Screenshot 06-15-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.8_1.png)

CGA:

![Screenshot CGA 07-22-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.10_cga_1.png)

MDA:

![Screenshot MDA 07-22-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.10_mda_1.png)

## STATUS

### TODO:

| Item	| Complete | TODO/Notes |
| ----------- | ----------- | ----------- |
| INT 09H Keyboard Decoding     | 90% | Ctrl-NumLock (pause), cleanup |
| INT 10H Video for CGA / MDA   | 90%  | Functions 8,9,A in CGA graphics modes 4-6 |
| Fixed ORGs for INT vectors    | 50%  | TODO when code is close to finalized |
| POST tests for all ICs        |     | Evaluate necessity of each vs code size to do it |
| RAM / Parity / NMI handling   |     |	Test on real hardware. Provide additional output for offending memory |

### Known Bugs / Incompatibilities

- ROM BASIC (INT 18) loads but doesn't work properly. Memory at 40:200 (or 50:100 or 60:0, which is ES and SS when BASIC is running) is being overwritten after first key press. Screen doesn't draw properly first time.
- SYSINFO 6.01 does not detect CGA/MDA. Shows "No Monitor", 0KB video RAM. Why?

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
3. Convert EXE to BIN (unfortunately DOS EXE2BIN cannot do this because it exceeds a single segment by 100H bytes). Included is a conversion program to do this and also calculate and insert the checksum. Or just remove the EXE header (the first 512 bytes of the EXE file) and then calculate the checksum manually, following step 4.
4. Calculate 8-bit checksum byte and insert into relative file offset `1FFF` in GLABIOS.ROM.

### Testing

Hampa Hug's excellent [PCE/ibmpc emulator](http://hampa.ch/pce/pce-ibmpc.html) works very well for build testing and debugging.  This provides a near-perfect hardware-accurate emulation of a PC ISA with inspection of support ICs, memory and code stepping.  My experience is the PC-DOS 2.0 branches work best since it uses the 8K ROM size used by 5150, 5160 v1 and many clones.

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
