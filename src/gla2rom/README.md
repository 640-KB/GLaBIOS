# GLaBIOS
## (GLaBIOS Libraries and Basic Input Output System)
A modern, scratch-built, open-source alternative for 8088 or Turbo PCs

Copyright (c) 2022, 640KB and contributors

## License

- GNU General Public License v3.0. See [LICENSE](LICENSE).

## GLa2ROM

This will convert the EXE output of MASM and LINK into a binary ROM suitable for writing to E/EPROM.  For E/EPROMs larger than 8K it may be necessary to write the image multiple times.  This must be run under DOS, DOXBox or your favorite DOS emulator.

### Usage

To produce an 8KiB ROM image.

`GLa2ROM GLABIOS.EXE GLABIOS.ROM`

#### Command Line Options

 /[1-8] - Duplicate 8K ROM this number of times

`GLA2ROM /[1-8] BIOS.EXE BIOS.ROM`

 #### ROM size:
	1 =  8K (default)
	2 = 16K
	4 = 32K
	8 = 64K