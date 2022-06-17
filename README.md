# GLaBIOS
## (General Libraries and Basic Input Output System)
A modern, scratch-built, open-source alternative BIOS for 8088 or Turbo PCs (coming soon)

Copyright (c) 2022, 640KB and contributors

## License

- GNU General Public License v3.0. See [LICENSE](LICENSE).

## FAQ

### Why another 8088 PC BIOS in 2022?

Because learning.  I've always wanted to know what actually happens inside the big gray box
and how everything actually works on a PC. Like a vintage car, radio or TV it's actually possible
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

It will be released soon, once it is deemed stable enough for testing!

### Screenshots

![Screenshot 06-15-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.8_1.png)

## STATUS

### TODO:

| Item	| Complete | TODO/Notes |
| ----------- | ----------- | ----------- |
| INT 09H Keyboard Decoding     | 60% | Complete all key combinations, cleanup |
| INT 10H Video for CGA / MDA   | 50%  | Graphic modes, scrolling, testing |
| INT 13H Floppy Disk Services  | 90% | Testing, cleanup, documentation |
| INT 05H Print Screen          | 0%  | |
| Fixed ORGs for INT vectors    | 0%  | TODO when code is closer to finalized |
| POST tests for all ICs        |     | Necessity of each vs code size to do it |
| RAM / Parity / NMI handling   |     |	Test on real hardware. Provide additional output for offending memory |
| Turbo XT support              |     | Additional testing on 10-16MHz real hardware |

### Known Bugs / Incompatibilities

- Norton SYSINFO v4.5 (?) pauses on load waiting for a keypress
- Using IBM XT/Xebec hard drive controller, if second HD is enabled but missing, odd looping INIT behavior on POST
- FreeDOS (2016) hangs on boot when booted from floppy disk
- ROM BASIC (INT 18) loads but doesn't work properly. Memory at 40:200 (or 50:100 or 60:0, which is ES and SS when BASIC is running) is being overwritten after first key press. Screen doesn't draw properly first time.

## BUILD NOTES:

### Assembler Version

Built using MASM 5.0 (or later). MASM and MASM syntax has been 
what I have used and most familiar with in assembly programming.
It also provides some sense of historical authenticity.
That said, it did not really occur to me in the beginning the irony of
writing an open-source project using a closed-source/commercial assembler. 
I wouldn't be opposed to convert someday to an open-source assembler (NASM, etc).

### Code Formatting
- Tab Size: 6 spaces. Indented with TAB characters.

### Code style:
GLaBIOS uses all UPPERCASE mnemonics because 1) it was the way I originally
learned assembly language 2) it's what's used in MASM 5 documentation
and manuals 3) it would have been an accepted practice in the era in when 
a PC BIOS clone was written.

### Build Process:

1. `MASM GLABIOS;`
2. `LINK GLABIOS;`  Will create GLABIOS.EXE.
3. Convert EXE to BIN (unfortunately DOS EXE2BIN cannot do this because it exceeds a single segment by 100H bytes). I will include a small tool to do this in the forthcoming distribution (TBD).
4. Calculate 8-bit checksum byte and insert into relative file offset `1FFF` in GLABIOS.ROM.

### Testing

Hampa Hug's excellent [PCE/ibmpc emulator](http://hampa.ch/pce/pce-ibmpc.html) works very well for build testing and debugging.  This provides a near-perfect hardware-accurate emulation of a PC ISA with inspection of support ICs, memory and code stepping.  My experience is the PC-DOS 2.0 branches work best since it uses the 8K ROM size used by 5150, 5160 v1 and many clones.

### Real Hardware Deployment

Minuszerodegrees has a lot of information about [original ROM types](http://minuszerodegrees.net/rom/rom.htm) and "modern" equivalents. I found using [Winbond W27E257](http://www.minuszerodegrees.net/rom/misc/Winbond%20W27E257%20as%2027C256%20replacement.htm) EEPROMs worked very well since it could be electrically erased and re-written quickly.  Since these are 32K EEPROMS, the image will need to be written 4 times sequentially.  From there I use a TL866 II Plus to write the images.

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
