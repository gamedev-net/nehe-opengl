INCLUDE = -I/usr/include -I/usr/local/glut/include
LIBDIR  = -L/usr/lib -L/usr/local/glut/glut/lib

COMPILERFLAGS = -xansi -fullwarn -O 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson1 

lesson1 : lesson1.o
	$(CC) $(CFLAGS) -o lesson1 $(LIBDIR) lesson1.o $(LIBRARIES)  
clean:
	rm lesson1 *.o
