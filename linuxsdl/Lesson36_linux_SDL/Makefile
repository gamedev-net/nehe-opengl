## NeHe's GLframe ported to SDL
## Fabio 'SnowDruid' Franchello
## snowdruid@tiscalinet.it

## Compiler
CC=gcc
## Linker
LD=$(CC)
## Flags
CPPFLAGS = -Wall -g -DLINUX `sdl-config --cflags`
LFLAGS = `sdl-config --libs` -lGL -lGLU

HEADERFILES = main.h

OBJS = main.o lesson36.o error.o

SRCS = main.c lesson36.c error.c

all : Lesson36
	chmod g+rw *.o

clean :
	rm -rf Lesson36 *.o

Lesson36 : ${OBJS}
	$(LD) -o $@ ${OBJS} ${LFLAGS}

depend :
	makedepend ${SRCS}

