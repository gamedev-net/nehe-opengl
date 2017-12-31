INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson9

lesson9 : lesson9.o
	$(CC) $(CFLAGS) -o lesson9 $(LIBDIR) lesson9.o $(LIBRARIES)  
clean:
	rm lesson9 *.o
