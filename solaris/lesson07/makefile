INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson7

lesson7 : lesson7.o
	$(CC) $(CFLAGS) -o lesson7 $(LIBDIR) lesson7.o $(LIBRARIES)  
clean:
	rm lesson7 *.o
