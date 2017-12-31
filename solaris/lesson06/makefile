INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson6

lesson6 : lesson6.o
	$(CC) $(CFLAGS) -o lesson6 $(LIBDIR) lesson6.o $(LIBRARIES)  
clean:
	rm lesson6 *.o
