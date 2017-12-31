lrc.exe lesson38.rc
lcc.exe NeHeGL.c
lcc.exe lesson38.c
lcclnk.exe -o lesson38.exe -subsystem windows -s lesson38.obj NeHeGL.obj lesson38.res opengl32.lib glu32.lib glaux.lib
ECHO Finished!

