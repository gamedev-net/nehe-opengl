INCLUDE = -I/usr/include -I/usr/local/glut/include
LIBDIR  = -L/usr/lib -L/usr/local/glut/glut/lib

COMPILERFLAGS = -xansi -fullwarn -O 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson3 

lesson3 : lesson3.o
	$(CC) $(CFLAGS) -o lesson3 $(LIBDIR) lesson3.o $(LIBRARIES)  
clean:
	rm lesson3 *.o
