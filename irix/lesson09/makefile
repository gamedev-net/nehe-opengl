include /usr/local/glutdefs
include /usr/include/make/commondefs

INCLUDE = -I/usr/include -I/usr/local/glut-3.7/include
LIBDIR  = -L/usr/local/glut-3.7/lib/glut.n32

COMPILERFLAGS = -mips3 -n32 -O -nostdinc 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lglut -lGLU -lGL -lXmu -lXext -lX11 -lm 

all:  lesson9

lesson9: lesson9.o
	$(CC) $(CFLAGS) -o lesson9 $(LIBDIR) lesson9.o $(LIBRARIES)  
clean:
	rm lesson9 *.o
