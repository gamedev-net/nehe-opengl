INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson5

lesson5 : lesson5.o
	$(CC) $(CFLAGS) -o lesson5 $(LIBDIR) lesson5.o $(LIBRARIES)  
clean:
	rm lesson5 *.o
