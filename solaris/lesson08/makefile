INCLUDE = -I/usr/openwin/include -I/usr/local/sparc_solaris/glut-3.7/include
LIBDIR  = -L/usr/openwin/lib      

COMPILERFLAGS = -Wall
CC = gcc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson8

lesson8 : lesson8.o
	$(CC) $(CFLAGS) -o lesson8 $(LIBDIR) lesson8.o $(LIBRARIES)  
clean:
	rm lesson8 *.o
