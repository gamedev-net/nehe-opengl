## NeHe's GLframe ported to SDL
## Fabio 'SnowDruid' Franchello
## snowdruid@tiscalinet.it

## Compiler
CC=gcc
## Linker
LD=$(CC)
## Flags
CPPFLAGS = -Wall -g -DLINUX `sdl-config --cflags`
LFLAGS = `sdl-config --libs` -L/usr/X11R6/lib -lGL -lGLU

HEADERFILES = main.h

OBJS = main.o lesson41.o error.o

SRCS = main.c lesson41.c error.c

all : lesson41
	chmod g+rw *.o

clean :
	rm -rf lesson41 *.o

lesson41 : ${OBJS}
	$(LD) -o $@ ${OBJS} ${LFLAGS}

depend :
	makedepend ${SRCS}

