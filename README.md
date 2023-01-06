# GLaBIOS
## (General Libraries and Basic Input Output System)
A modern, scratch-built, open-source alternative BIOS for vintage PC, XT, 8088 Clone or Turbo PCs.

Copyright &copy; 2022-2023, [640KB](mailto:640kb@glabios.org) and contributors.

## Version 0.2 released!

Version 0.2 is a significant update to version 0.1 adding numerous performance and stability improvements as well as new features and support for more hardware platforms.

[Download 0.2 ROMs](https://github.com/640-KB/GLaBIOS/releases)

[Source Code](https://github.com/640-KB/GLaBIOS/tree/main/src)

### You spoke, we listened!

The results of the poll for [tagline for the next major version](https://github.com/640-KB/GLaBIOS/discussions/14) are in, and the winner is... everybody!  GLaBIOS will now choose a different tagline on every reboot, based on mood.

## Features

- A complete [100% PC Compatible](#compatibility) BIOS for retro/vintage PC, XT, 8088 Clone, Turbo and Homebrew PCs.
- FAST! [Performance-optmized](doc/about/perf.md) CGA/MDA text and graphics routines.
- 5150 Cassette tape support.
- NEC V20 enhanced instruction set support.
- Multiple levels of "[CGA snow](https://en.wikipedia.org/wiki/Color_Graphics_Adapter#Limitations,_bugs_and_errata)" removal (configurable at build-time).
- Accurate PIT-based I/O timing for floppy disk, 10-15% faster seek and read times.
- Customizable POST test screen colors themes.
- Fits in an 8K ROM to drop in to any original PC or clone.

### Platforms Supported

- PC/XT 5160 and clones
- PC 5150 with cassette
- Turbo XTs (DTK, most clones)
- [Faraday FE2010A](https://github.com/skiselev/micro_8088/blob/master/Documentation/Faraday-XT_Controller-FE2010A.md)-based PCs ([Headstart Plus](http://oldcomputer.info/pc/hs_plus/index.htm)/VTI Vendex 33-XT/PC-10 and others)
- TD3900A-based PCs (Juko ST-12, UNIQUE, Auva, etc)
- Support for [EMM Homebrew 8088](https://www.homebrew8088.com/) with 8088, V20 or V40
- Emulator-optmized ([86Box](https://86box.net/) and others) for improved performance and stability
- Experimental support for [micro_8088](https://github.com/skiselev/micro_8088) / [NuXT](https://monotech.fwscart.com/) (looking for testers!)

## FAQ

### Why another 8088 PC BIOS in 2022?

There are other excellent BIOS projects out there each with it's own design goals and use cases. The goals for GLaBIOS are:

1. A collborative learning effort among the Retro Community
2. A fully open-source PC BIOS, built and improved by the community, free of outside proprietary or copyrighted code
3. Feature-complete with full support for original vintage hardware as well as new projects

### Where did the name originate?

If you aren't familiar with the reference, ask a gamer.

### Where is the source code?

[Right here](https://github.com/640-KB/GLaBIOS/tree/main/src)

### Screenshots

VGA with 8087 FPU:

![Screenshot VGA 07-29-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.11_vga_1.png)

EGA with V20:

![Screenshot VGA 07-29-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.0.11_ega_1.png)

CGA with 736K memory:

![Screenshot CGA 09-08-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.1.5_cga_mem_1.png)

Bad RAM detected! Use standard [address and bit indicator](http://minuszerodegrees.net/5160/ram/5160_ram_201_error_breakdown.jpg) to locate failed IC:

![Screenshot CGA 09-08-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.1.5_cga_memtst_1.png)

5150 with cassette:

![Screenshot 5150 Cas1](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_0.2.0_pc_cas_1.png)

#### Compatibility

1-2-3 ver 1A

![Screenshot 123 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_gb_123_1.png)

Flight Simulator 1.0

![Screenshot FS1 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/ss_gb_fs1_1.png)

## BUILD NOTES:

### Assembler Version

Build using MASM 5 or later.

### Build Process:

1. `MASM GLABIOS;`
2. `LINK GLABIOS;`  Will create GLABIOS.EXE.
3. Run `GLA2ROM GLABIOS` to convert to an 8 KiB ROM file.

OR

1. Convert EXE manually by removing the EXE header (the first 512 bytes of the EXE file) and extracting the last 8 KiB
2. Calculate 8-bit checksum byte and insert into relative file offset `1FFF` in GLABIOS.ROM.

### Testing

Hampa Hug's excellent [PCE/ibmpc emulator](http://hampa.ch/pce/pce-ibmpc.html) works very well for build testing and debugging.  This provides a near-perfect hardware-accurate emulation of a PC with inspection of ICs, memory and code stepping.  [86Box](http://86box.net/) and [PCem](http://pcem-emulator.co.uk/index.html) also work very well.

### Real Hardware Deployment

[Minuszerodegrees (-0°)](http://www.minuszerodegrees.net/) has a lot of information about [original ROM types](http://minuszerodegrees.net/rom/rom.htm) and "modern" equivalents. I found using [Winbond W27E257](http://www.minuszerodegrees.net/rom/misc/Winbond%20W27E257%20as%2027C256%20replacement.htm) EEPROMs worked very well since it could be electrically erased and re-written quickly.  Since these are 32K EEPROMS, the image will need to be written 4 times sequentially.  I use a TL866 II Plus to write the EEPROMs.

### Contact

Please send bug reports, feedback, questions or thoughts to 640kb@glabios.org or submit an [Issue](../../issues).

## References and Credits:

- https://stanislavs.org/helppc/
- [https://sites.google.com/site/pcdosretro/](https://web.archive.org/web/20220223124950/https://sites.google.com/site/pcdosretro/)
- http://www.minuszerodegrees.net/
- https://www.felixcloutier.com/x86/
- Font bitmaps by "VileR", ([CC BY-SA 4.0](https://int10h.org/oldschool-pc-fonts/readme/#legal_stuff))

### Further Credits to:

- The [Code Golf (CGCC)](https://codegolf.stackexchange.com/) community on Stack Exchange for helping me become a better ASM programmer.
- Hampa Hug for the excellent [PCE software](http://www.hampa.ch/pce/pce-ibmpc.html) that helped make development and debugging much easier.
- @Raffzahn, Contributor, Advisor and Meckerhut.
- @MadMaxx12345, @Makefile, @punishedbunny, @PickledDog and many others for testing, bug finding and feature suggestions.
- Dave Nault, my partner in crime for 2 semesters of college assembly language programming classes back in the day. Wherever you are buddy, hope you're doing well!

## License

- GNU General Public License v3.0. See [LICENSE](LICENSE).

### Disclaimer

This project is built upon the collective knowledge of the community by and for the benefit of the community.  Unless stated otherwise, cited public sources are considered as "public domain" or "fair use" of the copyrighted material as provided for in section 107 of the US Copyright Law.  If your copyrighted material appears in this project or on this web site and you disagree with our assessment that it constitutes "fair use," [contact us](mailto:640kb@glabios.org).
