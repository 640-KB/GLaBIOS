@ECHO OFF

REM Use Below for default build
MASM GLABIOS;

REM Uncomment below to specify build/architecture args
REM Example: 8088 Turbo:
REM MASM /DVER_DATE="08/22/22" /DARCH_TYPE="T" /DCPU_TYPE="8" GLABIOS;

LINK GLABIOS;
GLA2ROM\GLA2ROM GLABIOS.EXE GLABIOS.ROM