INCLUDE = -I/usr/include -I/usr/local/glut/include
LIBDIR  = -L/usr/lib -L/usr/local/glut/glut/lib

COMPILERFLAGS = -xansi -fullwarn -O 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson2 

lesson2 : lesson2.o
	$(CC) $(CFLAGS) -o lesson2 $(LIBDIR) lesson2.o $(LIBRARIES)  
clean:
	rm lesson2 *.o
