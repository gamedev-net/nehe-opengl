INCLUDE = -I/usr/include -I/usr/local/glut/include
LIBDIR  = -L/usr/lib -L/usr/local/glut/glut/lib

COMPILERFLAGS = -xansi -fullwarn -O 
CC = cc
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)
LIBRARIES = -lX11 -lXi -lXmu -lglut -lGL -lGLU -lm 

all:  lesson4 

lesson4 : lesson4.o
	$(CC) $(CFLAGS) -o lesson4 $(LIBDIR) lesson4.o $(LIBRARIES)  
clean:
	rm lesson4 *.o
