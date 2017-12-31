INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson2 

lesson2 : lesson2.o
	$(CC) $(CFLAGS) -o lesson2 $(LIBDIR) lesson2.o $(LIBRARIES)  
clean:
	rm lesson2 *.o
