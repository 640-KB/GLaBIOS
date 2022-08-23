# GLaBIOS
## (General Libraries and Basic Input Output System)
A modern, scratch-built, open-source alternative BIOS for vintage PC, XT, 8088 Clone or Turbo PCs.

Copyright (c) 2022, [640KB](640kb@glabios.org) and contributors.

## Video Performance

The [BIOS `INT 10h` CGA and MDA](https://en.wikipedia.org/wiki/INT_10H) routines were written to be as quick as possible. This can have a major visible impact on almost all UI functions, such as directory listing, text scrolling/movement in both DOS and many programs.

Here are the results of a few simple video benchmarks that were written to measure the overall speed/performance during development, timed using the BDA counter for a resolution of ~55ms.  These were then run on some other BIOS ROM binaries [found here](http://www.minuszerodegrees.net/xt_clone_bios/xt_clone_bios.htm) as baselines for comparison.

### CGA Text Drawing / Scrolling

This tests the BIOS TTY (`AH = 0Eh`) and text scrolling (`AH = 6h and 7h`).  It tests scrolling a two page document using the BIOS "Teletype output" (`AH = 0Eh`) first starting from a blank screen to simulate writing 1 page without scrolling and then 1 page with scrolling.  The test is then repeated by starting at the bottom of a page and writing 2 full pages scolling both.

All BIOS'es tested (appeared to) have some type of [CGA snow](https://en.wikipedia.org/wiki/Color_Graphics_Adapter#Limitations,_bugs_and_errata) removal.

![Screenshot CGA Text 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/perf_cga_txt_1c.png)

### MDA Text Drawing / Scrolling

This repeats the test as above, except that in MDA mode memory can be written directly without the necessity of CGA snow removal.

![Screenshot CGA Text 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/perf_mda_txt_1.png)

### CGA Graphics Drawing

This is a simple benchmark program drawing simple checkerboard patterns using only the BIOS `INT 10h` `AH = 0Bh` [write graphics pixel](https://en.wikipedia.org/wiki/INT_10H) routines in both 320x200 and 640x200 resolutions.

![Screenshot CGA Gfx 08-01-22](https://raw.githubusercontent.com/640-KB/GLaBIOS/main/images/perf_cga_gfx_1.png)
