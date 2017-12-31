INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson1 

lesson1 : lesson1.o
	$(CC) $(CFLAGS) -o lesson1 $(LIBDIR) lesson1.o $(LIBRARIES)  
clean:
	rm lesson1 *.o
