INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson3 

lesson3 : lesson3.o
	$(CC) $(CFLAGS) -o lesson3 $(LIBDIR) lesson3.o $(LIBRARIES)  
clean:
	rm lesson3 *.o
