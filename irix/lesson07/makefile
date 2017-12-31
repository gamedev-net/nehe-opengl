include /usr/local/glut-3.7/glutdefs
include /usr/include/make/commondefs

INCLUDE = -I/usr/include -I/usr/local/glut-3.7/include
LIBDIR  = -L/usr/local/glut-3.7/lib/glut.n32

COMPILERFLAGS = -mips3 -n32 -O -nostdinc 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lglut -lGLU -lGL -lXmu -lXext -lX11 -lm 

all:  lesson7

lesson7: lesson7.o
	$(CC) $(CFLAGS) -o lesson7 $(LIBDIR) lesson7.o $(LIBRARIES)  
clean:
	rm lesson7 *.o
