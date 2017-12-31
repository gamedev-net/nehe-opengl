## NeHe's GLframe ported to SDL
## by Gianni Cestari( giannicestari@libero.it)

## Compiler
CC=gcc
## Linker
LD=$(CC)
## Flags
CPPFLAGS = -Wall -g -DLINUX `sdl-config --cflags`
LFLAGS = `sdl-config --libs` -L/usr/X11R6/lib -lGL -lGLU

HEADERFILES = main.h

OBJS = main.o lesson40.o

SRCS = main.cpp lesson40.cpp

all : lesson40
	chmod g+rw *.o

clean :
	rm -rf lesson40 *.o

lesson40 : ${OBJS}
	$(LD) -o $@ ${OBJS} ${LFLAGS}

depend :
	makedepend ${SRCS}

