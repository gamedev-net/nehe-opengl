include /usr/local/glut-3.7/glutdefs
include /usr/include/make/commondefs

INCLUDE = -I/usr/include -I/usr/local/glut-3.7/include
LIBDIR  = -L/usr/local/glut-3.7/lib/glut.n32

COMPILERFLAGS = -mips3 -n32 -O -nostdinc 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lglut -lGLU -lGL -lXmu -lXext -lX11 -lm 

all:  lesson8

lesson8: lesson8.o
	$(CC) $(CFLAGS) -o lesson8 $(LIBDIR) lesson8.o $(LIBRARIES)  
clean:
	rm lesson8 *.o
