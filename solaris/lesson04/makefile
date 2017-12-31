INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson4 

lesson4 : lesson4.o
	$(CC) $(CFLAGS) -o lesson4 $(LIBDIR) lesson4.o $(LIBRARIES)  
clean:
	rm lesson4 *.o
